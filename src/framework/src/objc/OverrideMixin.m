/** -*-objc-*-
 *
 *   $Id$
 *
 *   Copyright (c) 2001 FUJIMOTO Hisakuni
 *
 **/
#import <Cocoa/Cocoa.h>
#import <stdarg.h>
#import <pthread.h>
#import "OverrideMixin.h"
#import "RBObject.h"
#import "RBSlaveObject.h"
#import "internal_macros.h"
#import "RBClassUtils.h"
#import "ocdata_conv.h"
#import "BridgeSupport.h"
#import "st.h"
#import <objc/objc-runtime.h>
#import "mdl_osxobjc.h"

#define OVMIX_LOG(fmt, args...) DLOG("OVMIX", fmt, ##args)

static void* alloc_from_default_zone(unsigned int size)
{
  return NSZoneMalloc(NSDefaultMallocZone(), size);
}

static struct objc_method_list* method_list_alloc(long cnt)
{
  struct objc_method_list* mlp;
  mlp = alloc_from_default_zone(sizeof(struct objc_method_list)
				+ (cnt-1) * sizeof(struct objc_method));
  mlp->obsolete = NULL;
  mlp->method_count = 0;
  return mlp;
}

static SEL super_selector(SEL a_sel)
{
  char selName[1024];

  snprintf (selName, sizeof selName, "super:%s", sel_getName(a_sel));
  return sel_registerName(selName);
}

static IMP super_imp(id rcv, SEL a_sel, IMP origin_imp)
{
  IMP ret = NULL;
  Class klass = [rcv class];

  while (klass = [klass superclass]) {
    ret = [klass instanceMethodForSelector: a_sel];
    if (ret && ret != origin_imp)
      return ret;
  }
  return NULL;
}

static id slave_obj_new(id rcv)
{
  return [[RBObject alloc] initWithClass: [rcv class] masterObject: rcv];
}

/**
 *  accessor for instance variables
 **/

static void set_slave(id rcv, id slave)
{
  object_setInstanceVariable(rcv, "m_slave", slave);
}

static id get_slave(id rcv)
{
  id ret;
  object_getInstanceVariable(rcv, "m_slave", (void*)(&ret));
  return ret;
}

/**
 * ruby method handler
 **/

/* Implemented in RBObject.m for now, still private. */
VALUE rbobj_call_ruby(id rbobj, SEL selector, VALUE args);

static void
ovmix_ffi_closure(ffi_cif* cif, void* resp, void** args, void* userdata)
{
  char *retval_octype;
  char **args_octypes;
  VALUE rb_args;
  unsigned i;
  VALUE retval;

  retval_octype = *(char **)userdata;
  args_octypes = ((char **)userdata) + 1;
  rb_args = rb_ary_new2(cif->nargs - 2);

  OVMIX_LOG("ffi_closure cif %p nargs %d sel '%s'", cif, cif->nargs, *(SEL *)args[1]); 

  for (i = 2; i < cif->nargs; i++) {
    VALUE arg;

    if (!ocdata_to_rbobj(Qnil, args_octypes[i - 2], args[i], &arg, NO))
      rb_raise(rb_eRuntimeError, "Can't convert Objective-C argument #%d of octype '%s' to Ruby value", i - 2, args_octypes[i - 2]);

    OVMIX_LOG("converted arg #%d to Ruby value %p", i - 2, arg);

    rb_ary_store(rb_args, i - 2, arg);
  }

  OVMIX_LOG("calling Ruby method...");
  retval = rbobj_call_ruby(*(id *)args[0], *(SEL *)args[1], rb_args);
  OVMIX_LOG("calling Ruby method done, retval %p", retval);

  // Make sure to sync boxed pointer ivars.
  for (i = 2; i < cif->nargs; i++) {
    struct bsBoxed *bs_boxed;
    if (is_boxed_ptr(args_octypes[i - 2], &bs_boxed)) {
      VALUE arg = RARRAY(rb_args)->ptr[i - 2];
      rb_bs_boxed_get_data(arg, bs_boxed->encoding, NULL, NULL);
    }
  }

  if (*encoding_skip_modifiers(retval_octype) != _C_VOID) {
    if (!rbobj_to_ocdata(retval, retval_octype, resp, YES))
      rb_raise(rb_eRuntimeError, "Can't convert return Ruby value to Objective-C value of octype '%s'", retval_octype);
  }
}

static struct st_table *ffi_imp_closures;
static pthread_mutex_t ffi_imp_closures_lock;

static IMP 
ovmix_imp_for_type(const char *type)
{
  BOOL ok;
  IMP imp;
  const char *error;
  unsigned i, argc;
  char *retval_type;
  char **arg_types;
  ffi_type *retval_ffi_type;
  ffi_type **arg_ffi_types;
  ffi_cif *cif;
  ffi_closure *closure;
  char **octypes;

  pthread_mutex_lock(&ffi_imp_closures_lock);
  imp = NULL;
  ok = st_lookup(ffi_imp_closures, (st_data_t)type, (st_data_t *)&imp);
  pthread_mutex_unlock(&ffi_imp_closures_lock); 
  if (ok)
    return imp;

  error = NULL;
  cif = NULL;
  closure = NULL;

  decode_method_encoding(type, nil, &argc, &retval_type, &arg_types, NO);

  arg_ffi_types = (ffi_type **)malloc(sizeof(ffi_type *) * (argc + 1));
  octypes = (char **)malloc(sizeof(char *) * (argc + 1)); /* first int is retval octype, then arg octypes */
  if (arg_ffi_types == NULL || octypes == NULL) {
    error = "Can't allocate memory";
    goto bails;
  }

  for (i = 0; i < argc; i++) {
    if (i >= 2)
      octypes[i - 1] = arg_types[i];
    arg_ffi_types[i] = ffi_type_for_octype(arg_types[i]);
  }
  octypes[0] = retval_type;
  retval_ffi_type = ffi_type_for_octype(retval_type);
  arg_ffi_types[argc] = NULL;

  cif = (ffi_cif *)malloc(sizeof(ffi_cif));
  if (cif == NULL) {
    error = "Can't allocate memory";
    goto bails;
  }

  if (ffi_prep_cif(cif, FFI_DEFAULT_ABI, argc, retval_ffi_type, arg_ffi_types) != FFI_OK) {
    error = "Can't prepare cif";
    goto bails;
  }

  closure = (ffi_closure *)malloc(sizeof(ffi_closure));
  if (closure == NULL) {
    error = "Can't allocate memory";
    goto bails;
  }

  if (ffi_prep_closure(closure, cif, ovmix_ffi_closure, octypes) != FFI_OK) {
    error = "Can't prepare closure";
    goto bails;
  }

  pthread_mutex_lock(&ffi_imp_closures_lock);
  imp = NULL;
  ok = st_lookup(ffi_imp_closures, (st_data_t)type, (st_data_t *)&imp);
  if (!ok)
    st_insert(ffi_imp_closures, (st_data_t)type, (st_data_t)closure);
  pthread_mutex_unlock(&ffi_imp_closures_lock);
  if (ok) {
    error = NULL;   
    goto bails;
  }
  
  imp = (IMP)closure;
  goto done;

bails:
  if (arg_ffi_types != NULL)
    free(arg_ffi_types);
  if (cif != NULL)
    free(cif);
  if (closure != NULL)
    free(closure);
  if (arg_types != NULL)
    free(arg_types);
  if (retval_type != NULL)
    free(retval_type);
  if (error != NULL)
    rb_raise(rb_eRuntimeError, error);

done:
  return imp; 
}

/**
 * instance methods implementation
 **/

static id imp_slave (id rcv, SEL method)
{
  return get_slave(rcv);
}

static id imp_rbobj (id rcv, SEL method)
{
  id slave = get_slave(rcv);
  VALUE rbobj = [slave __rbobj__];
  return (id)rbobj;
}

static id imp_respondsToSelector (id rcv, SEL method, SEL arg0)
{
  id ret;
  IMP simp = super_imp(rcv, method, (IMP)imp_respondsToSelector);
  id slave = get_slave(rcv);
  ret = (*simp)(rcv, method, arg0);
  if (ret == NULL)
    ret = (id)([slave respondsToSelector: arg0] != nil ? YES : NO);
  return ret;
}

static id imp_methodSignatureForSelector (id rcv, SEL method, SEL arg0)
{
  id ret;
  IMP simp = super_imp(rcv, method, (IMP)imp_methodSignatureForSelector);
  id slave = get_slave(rcv);
  ret = (*simp)(rcv, method, arg0);
  if (ret == nil)
    ret = [slave methodSignatureForSelector: arg0];
  return ret;
}

static id imp_forwardInvocation (id rcv, SEL method, NSInvocation* arg0)
{
  IMP simp = super_imp(rcv, method, (IMP)imp_forwardInvocation);
  id slave = get_slave(rcv);

  if ([slave respondsToSelector: [arg0 selector]])
    [slave forwardInvocation: arg0];
  else
    (*simp)(rcv, method, arg0);
  return nil;
}

static id imp_valueForUndefinedKey (id rcv, SEL method, NSString* key)
{
  id ret = nil;
  id slave = get_slave(rcv);

  if ([slave respondsToSelector: @selector(rbValueForKey:)])
    ret = (id)[rcv performSelector: @selector(rbValueForKey:) withObject: key];
  else
    ret = [rcv performSelector: super_selector(method) withObject: key];
  return ret;
}

static void imp_setValue_forUndefinedKey (id rcv, SEL method, id value, NSString* key)
{
  id slave = get_slave(rcv);
  id dict;

  /* In order to avoid ObjC values to be autorelease'd while they are still proxied in the
     Ruby world, we keep them in an internal hash. */
  if (object_getInstanceVariable(rcv, "__rb_kvc_dict__", (void *)&dict) == NULL) {
    dict = [[NSMutableDictionary alloc] init];
    object_setInstanceVariable(rcv, "__rb_kvc_dict__", dict);
  }

  if ([slave respondsToSelector: @selector(rbSetValue:forKey:)]) {
    [slave performSelector: @selector(rbSetValue:forKey:) withObject: value withObject: key];
    [dict setObject:value forKey:key];
  }
  else
    [rcv performSelector: super_selector(method) withObject: value withObject: key];
}

/**
 * class methods implementation
 **/
static id imp_c_alloc(Class klass, SEL method)
{
  id new_obj;
  id slave;
  new_obj = class_createInstance(klass, 0);
  slave = slave_obj_new(new_obj);
  set_slave(new_obj, slave);
  return new_obj;
}

static id imp_c_allocWithZone(Class klass, SEL method, NSZone* zone)
{
  id new_obj;
  id slave;
  new_obj = class_createInstanceFromZone(klass, 0, zone ? zone : NSDefaultMallocZone());
  slave = slave_obj_new(new_obj);
  set_slave(new_obj, slave);
  return new_obj;
}

static id imp_c_addRubyMethod(Class klass, SEL method, SEL arg0)
{
  Method me;
  struct objc_method_list* mlp;
  IMP imp;

  me = class_getInstanceMethod(klass, arg0);

  // warn if trying to override a method that isn't a member of the specified class
  if (me == NULL)
    rb_raise(rb_eRuntimeError, "could not add '%s' to class '%s': Objective-C cannot find it in the superclass", (char *)arg0, klass->name);
    
  // override method
  imp = ovmix_imp_for_type(me->method_types);
  if (me->method_imp == imp) {
    OVMIX_LOG("Already registered Ruby method by selector '%s' types '%s', skipping...", (char *)arg0, me->method_types);
    return nil;
  }
  
  mlp = method_list_alloc(2);
  mlp->method_list[0].method_name = me->method_name;
  mlp->method_list[0].method_types = strdup(me->method_types);
  mlp->method_list[0].method_imp = imp;
  mlp->method_count += 1;

  // super method
  mlp->method_list[1].method_name = super_selector(me->method_name);
  mlp->method_list[1].method_types = strdup(me->method_types);
  mlp->method_list[1].method_imp = me->method_imp;
  mlp->method_count += 1;
  
  class_addMethods(klass, mlp);
  OVMIX_LOG("Registered Ruby method by selector '%s' types '%s'", (char *)arg0, me->method_types);

  return nil;
}

static id imp_c_addRubyMethod_withType(Class klass, SEL method, SEL arg0, const char *type)
{
  struct objc_method_list* mlp = method_list_alloc(1);

  // add method
  mlp->method_list[0].method_name = sel_registerName((const char*)arg0);
  mlp->method_list[0].method_types = strdup(type);
  mlp->method_list[0].method_imp = ovmix_imp_for_type(type);
  mlp->method_count += 1;

  class_addMethods(klass, mlp);
  OVMIX_LOG("Registered Ruby method by selector '%s' types '%s'", (char *)arg0, type);
  return nil;
}

static struct objc_ivar imp_ivars[] = {
  {				// struct objc_ivar {
    "m_slave",			//   char *ivar_name;
    "@",			//   char *ivar_type;
    0,				//    int ivar_offset;
#ifdef __alpha__
    0				//    int space;
#endif
  }                             // } ivar_list[1];
};

/**
 *  instance methods
 **/
static const char* imp_method_names[] = {
  "__slave__",
  "__rbobj__",
  "respondsToSelector:",
  "methodSignatureForSelector:",
  "forwardInvocation:",
  "valueForUndefinedKey:",
  "setValue:forUndefinedKey:",
};

static struct objc_method imp_methods[] = {
  { NULL,
    "@4@4:8",
    (IMP)imp_slave 
  },
  { NULL,
    "L4@4:8",
    (IMP)imp_rbobj 
  },
  { NULL,
    "c8@4:8:12",
    (IMP)imp_respondsToSelector
  },
  { NULL,
    "@8@4:8:12",
    (IMP)imp_methodSignatureForSelector
  },
  { NULL,
    "v8@4:8@12",
    (IMP)imp_forwardInvocation
  },
  { NULL,
    "@12@0:4@8",
    (IMP)imp_valueForUndefinedKey
  },
  { NULL,
    "v16@0:4@8@12",
    (IMP)imp_setValue_forUndefinedKey
  },
};


/**
 *  class method for pure Objective-C classes
 **/
static const char* imp_c_pure_method_names[] = {
  "addRubyMethod:",
  "addRubyMethod:withType:"
};

static struct objc_method imp_c_pure_methods[] = {
  { NULL,
    "@4@4:8:12",
    (IMP)imp_c_addRubyMethod
  },
  { NULL,
    "@4@4:8:12*16",
    (IMP)imp_c_addRubyMethod_withType
  }
};

/**
 *  class methods
 **/
static const char* imp_c_method_names[] = {
  "alloc",
  "allocWithZone:"
};

static struct objc_method imp_c_methods[] = {
  { NULL,
    "@4@4:8",
    (IMP)imp_c_alloc
  },
  { NULL,
    "@8@4:8^{_NSZone=}12",
    (IMP)imp_c_allocWithZone
  }
};

long override_mixin_ivar_list_size()
{
  long cnt = sizeof(imp_ivars) / sizeof(struct objc_ivar);
  return (sizeof(struct objc_ivar_list)
	  - sizeof(struct objc_ivar)
	  + (cnt * sizeof(struct objc_ivar)));
}

struct objc_ivar_list* override_mixin_ivar_list()
{
  static struct objc_ivar_list* imp_ilp = NULL;
  if (imp_ilp == NULL) {
    int i;
    imp_ilp = alloc_from_default_zone(override_mixin_ivar_list_size());
    imp_ilp->ivar_count = sizeof(imp_ivars) / sizeof(struct objc_ivar);
    for (i = 0; i < imp_ilp->ivar_count; i++) {
      imp_ilp->ivar_list[i] = imp_ivars[i];
    }
  }
  return imp_ilp;
}

struct objc_method_list* override_mixin_method_list()
{
  static struct objc_method_list* imp_mlp = NULL;
  if (imp_mlp == NULL) {
    int i;
    long cnt = sizeof(imp_methods) / sizeof(struct objc_method);
    imp_mlp = method_list_alloc(cnt);
    for (i = 0; i < cnt; i++) {
      imp_mlp->method_list[i] = imp_methods[i];
      imp_mlp->method_list[i].method_name = sel_getUid(imp_method_names[i]);
      imp_mlp->method_count += 1;
    }
  }
  return imp_mlp;
}

struct objc_method_list* override_mixin_class_method_list()
{
  static struct objc_method_list* imp_c_mlp = NULL;
  if (imp_c_mlp == NULL) {
    int i;
    long cnt = sizeof(imp_c_methods) / sizeof(struct objc_method);
    imp_c_mlp = method_list_alloc(cnt);
    for (i = 0; i < cnt; i++) {
      imp_c_mlp->method_list[i]  = imp_c_methods[i];
      imp_c_mlp->method_list[i].method_name = sel_getUid(imp_c_method_names[i]);
      imp_c_mlp->method_count += 1;
    }
  }
  return imp_c_mlp;
}

static struct objc_method_list* override_mixin_class_pure_method_list()
{
  static struct objc_method_list* imp_c_pure_mlp = NULL;
  if (imp_c_pure_mlp == NULL) {
    int i;
    long cnt = sizeof(imp_c_pure_methods) / sizeof(struct objc_method);
    imp_c_pure_mlp = method_list_alloc(cnt);
    for (i = 0; i < cnt; i++) {
      imp_c_pure_mlp->method_list[i]  = imp_c_pure_methods[i];
      imp_c_pure_mlp->method_list[i].method_name = sel_getUid(imp_c_pure_method_names[i]);
      imp_c_pure_mlp->method_count += 1;
    }
  }
  return imp_c_pure_mlp;
}

void init_ovmix(void)
{   
  ffi_imp_closures = st_init_strtable();
  pthread_mutex_init(&ffi_imp_closures_lock, NULL);
  class_addMethods(objc_lookUpClass("NSObject"), override_mixin_class_pure_method_list()); 
}

@implementation NSObject (__rbobj__)

+ (VALUE)__rbclass__
{
  return rb_const_get(osx_s_module(), rb_intern(((struct objc_class *)self)->name))
; 
}

@end

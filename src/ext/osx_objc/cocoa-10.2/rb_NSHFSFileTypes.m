#import <LibRuby/cocoa_ruby.h>
#import <RubyCocoa/ocdata_conv.h>
#import <Foundation/Foundation.h>

extern void rbarg_to_nsarg(VALUE rbarg, int octype, void* nsarg, id pool, int index);
extern VALUE nsresult_to_rbresult(int octype, const void* nsresult, id pool);
static const int VA_MAX = 4;


  /**** functions ****/
// NSString *NSFileTypeForHFSTypeCode(OSType hfsFileTypeCode);
static VALUE
osx_NSFileTypeForHFSTypeCode(VALUE mdl, VALUE a0)
{
  rb_notimplement();
}

// OSType NSHFSTypeCodeFromFileType(NSString *fileTypeString);
static VALUE
osx_NSHFSTypeCodeFromFileType(VALUE mdl, VALUE a0)
{
  rb_notimplement();
}

// NSString *NSHFSTypeOfFile(NSString *fullFilePath);
static VALUE
osx_NSHFSTypeOfFile(VALUE mdl, VALUE a0)
{
  NSString * ns_result;

  NSString * ns_a0;

  VALUE rb_result;
  id pool = [[NSAutoreleasePool alloc] init];
  /* a0 */
  rbarg_to_nsarg(a0, _C_ID, &ns_a0, pool, 0);

  ns_result = NSHFSTypeOfFile(ns_a0);

  rb_result = nsresult_to_rbresult(_C_ID, &ns_result, pool);
  [pool release];
  return rb_result;
}

void init_NSHFSFileTypes(VALUE mOSX)
{
  /**** functions ****/
  rb_define_module_function(mOSX, "NSFileTypeForHFSTypeCode", osx_NSFileTypeForHFSTypeCode, 1);
  rb_define_module_function(mOSX, "NSHFSTypeCodeFromFileType", osx_NSHFSTypeCodeFromFileType, 1);
  rb_define_module_function(mOSX, "NSHFSTypeOfFile", osx_NSHFSTypeOfFile, 1);
}

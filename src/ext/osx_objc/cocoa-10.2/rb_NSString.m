#import "osx_ruby.h"
#import "ocdata_conv.h"
#import <Foundation/Foundation.h>

extern void rbarg_to_nsarg(VALUE rbarg, int octype, void* nsarg, id pool, int index);
extern VALUE nsresult_to_rbresult(int octype, const void* nsresult, id pool);
static const int VA_MAX = 4;


  /**** constants ****/
// NSString * const NSParseErrorException;
static VALUE
osx_NSParseErrorException(VALUE mdl)
{
  return nsresult_to_rbresult(_C_ID, &NSParseErrorException, nil);
}

// NSString * const NSCharacterConversionException;
static VALUE
osx_NSCharacterConversionException(VALUE mdl)
{
  return nsresult_to_rbresult(_C_ID, &NSCharacterConversionException, nil);
}

// void * _NSConstantStringClassReference;
static VALUE
osx__NSConstantStringClassReference(VALUE mdl)
{
  return nsresult_to_rbresult(_PRIV_C_PTR, &_NSConstantStringClassReference, nil);
}

void init_NSString(VALUE mOSX)
{
  /**** enums ****/
  rb_define_const(mOSX, "NSCaseInsensitiveSearch", INT2NUM(NSCaseInsensitiveSearch));
  rb_define_const(mOSX, "NSLiteralSearch", INT2NUM(NSLiteralSearch));
  rb_define_const(mOSX, "NSBackwardsSearch", INT2NUM(NSBackwardsSearch));
  rb_define_const(mOSX, "NSAnchoredSearch", INT2NUM(NSAnchoredSearch));
  rb_define_const(mOSX, "NSASCIIStringEncoding", INT2NUM(NSASCIIStringEncoding));
  rb_define_const(mOSX, "NSNEXTSTEPStringEncoding", INT2NUM(NSNEXTSTEPStringEncoding));
  rb_define_const(mOSX, "NSJapaneseEUCStringEncoding", INT2NUM(NSJapaneseEUCStringEncoding));
  rb_define_const(mOSX, "NSUTF8StringEncoding", INT2NUM(NSUTF8StringEncoding));
  rb_define_const(mOSX, "NSISOLatin1StringEncoding", INT2NUM(NSISOLatin1StringEncoding));
  rb_define_const(mOSX, "NSSymbolStringEncoding", INT2NUM(NSSymbolStringEncoding));
  rb_define_const(mOSX, "NSNonLossyASCIIStringEncoding", INT2NUM(NSNonLossyASCIIStringEncoding));
  rb_define_const(mOSX, "NSShiftJISStringEncoding", INT2NUM(NSShiftJISStringEncoding));
  rb_define_const(mOSX, "NSISOLatin2StringEncoding", INT2NUM(NSISOLatin2StringEncoding));
  rb_define_const(mOSX, "NSUnicodeStringEncoding", INT2NUM(NSUnicodeStringEncoding));
  rb_define_const(mOSX, "NSWindowsCP1251StringEncoding", INT2NUM(NSWindowsCP1251StringEncoding));
  rb_define_const(mOSX, "NSWindowsCP1252StringEncoding", INT2NUM(NSWindowsCP1252StringEncoding));
  rb_define_const(mOSX, "NSWindowsCP1253StringEncoding", INT2NUM(NSWindowsCP1253StringEncoding));
  rb_define_const(mOSX, "NSWindowsCP1254StringEncoding", INT2NUM(NSWindowsCP1254StringEncoding));
  rb_define_const(mOSX, "NSWindowsCP1250StringEncoding", INT2NUM(NSWindowsCP1250StringEncoding));
  rb_define_const(mOSX, "NSISO2022JPStringEncoding", INT2NUM(NSISO2022JPStringEncoding));
  rb_define_const(mOSX, "NSMacOSRomanStringEncoding", INT2NUM(NSMacOSRomanStringEncoding));
  rb_define_const(mOSX, "NSProprietaryStringEncoding", INT2NUM(NSProprietaryStringEncoding));

  /**** constants ****/
  rb_define_module_function(mOSX, "NSParseErrorException", osx_NSParseErrorException, 0);
  rb_define_module_function(mOSX, "NSCharacterConversionException", osx_NSCharacterConversionException, 0);
  rb_define_module_function(mOSX, "_NSConstantStringClassReference", osx__NSConstantStringClassReference, 0);
}
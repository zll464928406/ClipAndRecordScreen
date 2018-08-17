//
//  NSString+Extension.h
//  XeShare
//
//  Created by Hillman Li on 10/23/12.
//
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface NSString (Extension)

+ (id)stringWithFormat:(NSString *)format array:(NSArray*) arguments;
+ (NSString *)safeStringForArrayItem:(NSString *)unSafeString;
- (NSString *)trim;
- (BOOL)isNotEmpty;
- (NSString *)briefStringWithLength:(int)length;
//- (CGFloat)caculateHeightWithFontType:(NSFont *) font rowWidth:(CGFloat)rowWidth;
//- (CGFloat)caculateHeightWithFontType:(NSFont *) font;
- (NSSize)caculateSizeWithFontType:(NSFont *)font rowWidth:(CGFloat)rowWidth;
- (NSSize)caculateSizeWithFontType:(NSFont *) font;
- (id)JSONValue;

- (NSString*)filterNumbers;

- (NSString*)urlEncode;

- (BOOL)isSamePath:(NSString *) path;

- (BOOL)containsString:(NSString *)string;
- (BOOL)containsString:(NSString *)string options:(NSStringCompareOptions)options;
+ (BOOL)isValidateEmail:(NSString *)emailString;
@end


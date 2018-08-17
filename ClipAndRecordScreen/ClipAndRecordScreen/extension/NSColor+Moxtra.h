//
//  NSColor+Moxtra.h
//  Moxtra
//
//  Created by Raymond Xu on 12/24/13.
//  Copyright (c) 2013 Mxotra. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (Moxtra)

+ (NSColor *)moxtraGridColor;
+ (NSColor *)moxtraWhiteColor;
+ (NSColor *)moxtraMeetBaseColor;

+ (NSColor *)moxtraBackgroundColorStyle1;
+ (NSColor *)moxtraBackgroundColorStyle2;
+ (NSColor *)moxtraBackgroundColorStyle3;

+ (NSColor *)moxtraDarkGrayColor;

+ (NSColor *)moxtraBlueColor;
+ (NSColor *)moxtraOrangeColor;
+ (NSColor *)moxtraGreenColor;
+ (NSColor *)moxtraRedColor;
+ (NSColor *)moxtraBadgeColor;
+ (NSColor *)moxtraPageTextureColor;
+ (NSColor *)moxtraDarkBlueColor;
+ (NSColor *)moxtraGray60Color;

+ (NSColor *)brandingColor;
+ (NSColor *)moxtraBrandingColor;

+ (NSColor *)moxtraColorWithHexString:(NSString *)hexString;

@end

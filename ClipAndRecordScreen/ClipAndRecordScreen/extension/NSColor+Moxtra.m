//
//  NSColor+Moxtra.m
//  Moxtra
//
//  Created by Raymond Xu on 12/24/13.
//  Copyright (c) 2013 Mxotra. All rights reserved.
//

#import "NSColor+Moxtra.h"

@implementation NSColor (Moxtra)

+ (NSColor *)moxtraGridColor
{
    return [NSColor gridColor];
}

+ (NSColor *)moxtraWhiteColor
{
    return [NSColor whiteColor];
}

+ (NSColor *)moxtraMeetBaseColor
{
    return [NSColor colorWithDeviceRed:0.99 green:0.52 blue:0.14 alpha:1];
}

+ (NSColor *)moxtraBackgroundColorStyle1
{
    return [NSColor colorWithDeviceRed:0.97 green:0.97 blue:0.97 alpha:1];
}

+ (NSColor *)moxtraBackgroundColorStyle2
{
    return [NSColor whiteColor];
}

+ (NSColor *)moxtraBackgroundColorStyle3
{
    return [NSColor colorWithDeviceRed:0.94 green:0.94 blue:0.96 alpha:1];
}

+ (NSColor *)moxtraDarkGrayColor
{
    return [NSColor colorWithDeviceRed:0.2f green:0.2f blue:0.2f alpha:1.0f];
}

+ (NSColor *)moxtraBlueColor;
{
    return [NSColor colorWithDeviceRed:0.0f green:0.51f blue:0.84f alpha:1.0f];
}

+ (NSColor *)moxtraOrangeColor;
{
    return [NSColor colorWithDeviceRed:1.0f green:0.52f blue:0.0f alpha:1.0f];
}

+ (NSColor *)moxtraGreenColor;
{
    return [NSColor moxtraColorWithHex:0x00C853 alpha:1.0f];
}

+ (NSColor *)moxtraRedColor;
{
    return [NSColor redColor];
}

+ (NSColor *)moxtraBadgeColor;
{
    return  [NSColor redColor];
}

+ (NSColor *)moxtraPageTextureColor
{
    return [NSColor colorWithPatternImage:[NSImage imageNamed:@"texture_page"]];
}

+ (NSColor *)moxtraDarkBlueColor;
{
    return [NSColor colorWithDeviceRed:0.02f green:0.22f blue:0.42f alpha:1.0f];
}

+ (NSColor *)moxtraGray60Color;
{
    return [NSColor moxtraColorWithHex:0x646466 alpha:1.0f];
}

+ (NSColor *)moxtraBrandingColor
{
    return [NSColor moxtraBlueColor];
}

+ (NSColor *)moxtraColorWithHexString:(NSString *)hexString
{
    if(hexString.length == 0)
        return nil;
    
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    
    return [NSColor colorWithDeviceRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (NSColor *)brandingColor;
{
#ifdef VCCHAT_VERSION
    return [NSColor colorWithDeviceRed:205/255.0f green:4/255.0f blue:11/255.0f alpha:0.81f];
#endif
    return [NSColor colorWithDeviceRed:37/255.0f green:145/255.0f blue:214/255.0f alpha:0.81f];
}

+ (NSColor *)moxtraColorWithHex:(NSInteger)hex alpha:(CGFloat)alpha
{
    return [NSColor colorWithRed:(((hex >> 16) & 0xff) / 255.0f) green:(((hex >> 8) & 0xff) / 255.0f) blue:(((hex) & 0xff) / 255.0f) alpha:alpha];
}

@end

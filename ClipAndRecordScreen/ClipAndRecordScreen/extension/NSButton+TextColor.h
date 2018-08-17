//
//  NSButton+TextColor.h
//
//  Created by Elton Liu on 8/28/11.
//  Copyright 2011 YellowBull. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSButton (TextColor)

- (NSColor *)textColor;
- (void)setTextColor:(NSColor *)textColor;
- (void)setText:(NSString *)text withColor:(NSColor *)textColor isShadow:(BOOL)shadow;
- (void)setText:(NSString *)text withColor:(NSColor *)textColor isUnderLine:(BOOL)underLine;

@end


@interface NSPointingHandButton : NSButton


@end

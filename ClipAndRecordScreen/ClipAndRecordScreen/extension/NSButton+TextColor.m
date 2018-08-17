//
//  NSButton+TextColor.m
//
//  Created by Elton Liu on 8/28/11.
//  Copyright 2011 YellowBull. All rights reserved.
//

#import "NSButton+TextColor.h"

@implementation NSButton (TextColor)

- (NSColor *)textColor
{
    NSAttributedString *attrTitle = [self attributedTitle];
    NSUInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, MIN(len, 1)); // take color from first char
    NSDictionary *attrs = [attrTitle fontAttributesInRange:range];
    NSColor *textColor = [NSColor controlTextColor];
    if (attrs) {
        textColor = [attrs objectForKey:NSForegroundColorAttributeName];
    }
    return textColor;
}

- (void)setTextColor:(NSColor *)textColor
{
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc]
											initWithAttributedString:[self attributedTitle]];
    NSUInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:NSForegroundColorAttributeName
                      value:textColor
                      range:range];
    [attrTitle fixAttributesInRange:range];
    [self setAttributedTitle:attrTitle];
}

- (void)setText:(NSString *)text withColor:(NSColor *)textColor isShadow:(BOOL)shadow
{
    NSShadow* shadw = [[NSShadow alloc] init];
    
    [shadw setShadowColor:[NSColor grayColor]];
    [shadw setShadowOffset:NSMakeSize( 0, -1 )];
    [shadw setShadowBlurRadius:1.0];
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc]
                                            initWithAttributedString:[self attributedTitle]];
    NSUInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:NSForegroundColorAttributeName
                      value:textColor
                      range:range];
    if (shadow) {
        [attrTitle addAttribute:NSShadowAttributeName value:shadw range:range];
    }
    else {
        [attrTitle removeAttribute:NSShadowAttributeName range:range];
    }
	
    [attrTitle fixAttributesInRange:range];
    [attrTitle replaceCharactersInRange:range withString:text];
    [self setAttributedTitle:attrTitle];
}

- (void)setText:(NSString *)text withColor:(NSColor *)textColor isUnderLine:(BOOL)underLine
{
    NSShadow* shadw = [[NSShadow alloc] init];
    
    [shadw setShadowColor:[NSColor grayColor]];
    [shadw setShadowOffset:NSMakeSize( 0, -1 )];
    [shadw setShadowBlurRadius:1.0];
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc]
                                            initWithAttributedString:[self attributedTitle]];
    NSUInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:NSForegroundColorAttributeName
                      value:textColor
                      range:range];
    if (underLine) {
        [attrTitle addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
    }
    else {
        [attrTitle removeAttribute:NSUnderlineStyleAttributeName range:range];
    }
    
    [attrTitle fixAttributesInRange:range];
    [attrTitle replaceCharactersInRange:range withString:text];
    [self setAttributedTitle:attrTitle];
}
@end


@implementation NSPointingHandButton

- (void)resetCursorRects
{
	[super resetCursorRects];
	[self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];
}

@end


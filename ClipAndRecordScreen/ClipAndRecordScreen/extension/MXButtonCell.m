//
//  MXButtonCell.m
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 6/27/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import "MXButtonCell.h"

@implementation MXButtonCell


- (NSRect) drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    NSGraphicsContext* ctx = [NSGraphicsContext currentContext];
    
    [ctx saveGraphicsState];
    NSMutableAttributedString *attrString = [title mutableCopy];
    [attrString beginEditing];
    NSColor *titleColor = self.textColor;
    
    frame.origin.x += self.texteEdgeInsets.left;
    frame.origin.y += self.texteEdgeInsets.top;
    frame.size.width -= self.texteEdgeInsets.right - self.texteEdgeInsets.left;
    frame.size.height -= self.texteEdgeInsets.bottom - self.texteEdgeInsets.top;
    
    [attrString addAttribute:NSForegroundColorAttributeName value:titleColor range:NSMakeRange(0, [[self title] length])];
    [attrString endEditing];
    NSRect r = [super drawTitle:attrString withFrame:frame inView:controlView];
    // 5) Restore the graphics state
    [ctx restoreGraphicsState];
    
    return r;
}

- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView
{
    frame.origin.x += self.imageEdgeInsets.left;
    frame.origin.y += self.imageEdgeInsets.top;
    frame.size.width -= self.imageEdgeInsets.right - self.imageEdgeInsets.left;
    frame.size.height -= self.imageEdgeInsets.bottom - self.imageEdgeInsets.top;
    
    [super drawImage:image withFrame:frame inView:controlView];
    
}


@end

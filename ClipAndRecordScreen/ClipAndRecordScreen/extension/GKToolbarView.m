//
//  GKToolbarView.m
//  Moxtra
//
//  Created by Raymond Xu on 11/8/13.
//  Copyright (c) 2013 Mxotra. All rights reserved.
//

#import "GKToolbarView.h"
#import "NSButton+TextColor.h"

@implementation GKToolbarView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.

        self.clipAreaButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 129, 30)];
        [self.clipAreaButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin ];
        [self.clipAreaButton setButtonType:NSMomentaryChangeButton];
        [self.clipAreaButton setBordered:NO];
        [self.clipAreaButton setImagePosition:NSImageOverlaps];
        [self.clipAreaButton setTitle:NSLocalizedString(@"Clip Screen Area", @"Clip Screen Area")];
        [self.clipAreaButton setTextColor:[NSColor whiteColor]];
        [self.clipAreaButton setImage:[NSImage imageNamed:@"black_button"]];
        [self addSubview:self.clipAreaButton];
        
        self.clipFullButton = [[NSButton alloc] initWithFrame:NSMakeRect(139, 0, 129, 30)];
        [self.clipFullButton setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin ];
        [self.clipFullButton setButtonType:NSMomentaryChangeButton];
        [self.clipFullButton setBordered:NO];
        [self.clipFullButton setImagePosition:NSImageOverlaps];
        [self.clipFullButton setTitle:NSLocalizedString(@"Clip Full Screen", @"Clip Full Screen")];
        [self.clipFullButton setTextColor:[NSColor whiteColor]];
        [self.clipFullButton setImage:[NSImage imageNamed:@"black_button"]];
        [self addSubview:self.clipFullButton];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    //fill outer rect
    //[[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1] set];
    //[[NSColor redColor] set];
    //NSRectFill(self.bounds);
}

@end

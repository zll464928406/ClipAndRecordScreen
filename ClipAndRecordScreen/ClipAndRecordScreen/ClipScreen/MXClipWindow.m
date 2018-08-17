//
//  MXClipWindow.m
//  MoxtraClipDemo
//
//  Created by sunny on 2017/12/11.
//  Copyright © 2017年 moxtra. All rights reserved.
//

#import "MXClipWindow.h"

@implementation MXClipWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen
{
    if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:NSBackingStoreBuffered defer:NO screen:screen]) {
        [self setBackgroundColor:[NSColor clearColor]];
        [self setAlphaValue:1];
        [self setAcceptsMouseMovedEvents:YES];
        [self setFloatingPanel:YES];
        [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];
        [self setMovableByWindowBackground:NO];
        [self setExcludedFromWindowsMenu:YES];
        [self setOpaque:NO];
        [self setHasShadow:NO];
        [self setHidesOnDeactivate:NO];
        [self setLevel:kCGMaximumWindowLevel];
        [self setRestorable:NO];
        [self disableSnapshotRestoration];
        [self setLevel:kCGMaximumWindowLevel];
        
        self.movable = NO;
    }
    return self;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

- (void)dealloc
{
    //NSLog(@"snip window dealloc");
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    //[super mouseMoved:theEvent];
    if ([self.mouseDelegate respondsToSelector:@selector(mouseMoved:)])
    {
        [self.mouseDelegate mouseMoved:theEvent];
    }
//    NSLog(@"mouseMoved-Window: %@", self.title);
}

- (void)mouseDown:(NSEvent *)theEvent
{
    //[super mouseDown:theEvent];
    if ([self.mouseDelegate respondsToSelector:@selector(mouseDown:)])
    {
        [self.mouseDelegate mouseDown:theEvent];
    }
    
    //NSLog(@"mouseDown-Window: %@", self.title);
}

- (void)mouseUp:(NSEvent *)theEvent
{
    //[super mouseUp:theEvent];
    if ([self.mouseDelegate respondsToSelector:@selector(mouseUp:)])
    {
        [self.mouseDelegate mouseUp:theEvent];
    }
    
//    NSLog(@"mouseUp-Window: %@", self.title);
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
//    NSLog(@"rightMouseUp-Window: %@", self.title);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    //[super mouseDragged:theEvent];
//
    if ([self.mouseDelegate respondsToSelector:@selector(mouseDragged:)])
    {
        [self.mouseDelegate mouseDragged:theEvent];
    }
//    NSLog(@"mouseDragged-Window: %@", self.title);
}

- (void)keyDown:(NSEvent *)event
{
//    if ([event keyCode] == kKEY_ESC_CODE) {
//        NSLog(@"Escape has been pressed");
//        [self orderOut:nil];
//        [[SnipManager sharedInstance] endCapture:nil];
//        return;
//    }
    [super keyDown:event];
}

@end

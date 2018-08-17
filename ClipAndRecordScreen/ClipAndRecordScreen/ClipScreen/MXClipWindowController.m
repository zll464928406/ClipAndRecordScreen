//
//  MXClipWindowController.m
//  MoxtraClipDemo
//
//  Created by sunny on 2017/12/11.
//  Copyright © 2017年 moxtra. All rights reserved.
//

#import "MXClipWindowController.h"
#import "GKResizeableCropOverlayView.h"
#import "MXClipToolbarViewController.h"
#import "MXClipView.h"
#import "SnipUtil.h"
#import "NSImage+Screenshot.h"
#import "MXClipScreenManager.h"
#import "NSScreen+PointConversion.h"

@interface MXClipWindowController () <MXClipViewDelegate, MXClipToolbarViewControllerDelegate>

@property (nonatomic, strong) MXClipView *clipView;
@property (nonatomic, strong) MXClipToolbarViewController *toolbarViewController;

@property (nonatomic, strong) id eventMonitor;
@property (nonatomic, assign) NSRect lastWindowRect;
@property (nonatomic, assign) NSInteger lastWindowNumber;

@end

@implementation MXClipWindowController

- (instancetype)initWithDelegate:(id<MXClipWindowControllerDelegate>) delegate
{
    self = [super init];
    if (self)
    {
        self.delegate = delegate;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

#pragma mark - Public Methods
- (void)startCaptureWithScreen:(NSScreen *)screen
{
    //set all windows in screen
    self.screen = screen;
    
    self.window  = [[MXClipWindow alloc] initWithContentRect:[screen frame] styleMask:NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO screen:screen];
    self.clipView = [[MXClipView alloc] initWithFrame:NSMakeRect(0, 0, [screen frame].size.width, [screen frame].size.height) type:MXClipViewClipType];
    self.clipView.delegate = self;
    self.clipView.wantsLayer = YES;
    self.clipView.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.4].CGColor;
    self.clipView.haveSetClearColor = NO;
    self.window.contentView = self.clipView;
    [self.window setFrame:screen.frame display:YES animate:NO];
    [self.window makeKeyAndOrderFront:nil];
//    [self showWindow:nil];
    
    self.toolbarViewController = [[MXClipToolbarViewController alloc] init];
    self.toolbarViewController.delegate = self;
    NSRect rect = NSMakeRect(0, 0, screen.frame.size.width, screen.frame.size.height);
    [self.clipView showClipViewWithFrame:rect withToolbar:self.toolbarViewController.view];
    self.lastWindowRect = rect;
    
    // esc key pressed
    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSEventMaskKeyDown) handler:^(NSEvent *incomingEvent) {
        NSEvent *result = incomingEvent;
        if ([incomingEvent type] == NSEventTypeKeyDown && incomingEvent.keyCode == 53)
        {
            [self endCapture];
            if ([self.delegate respondsToSelector:@selector(clipWindowControllerDidCancel:)])
            {
                [self.delegate clipWindowControllerDidCancel:self];
            }
            [[NSCursor arrowCursor] set];
        }
        
        return result;
    }];
}

- (void)endCapture
{
    if ([self.window isVisible])
    {
        [self.window orderOut:nil];
    }
    [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
    self.clipView = nil;
}

#pragma mark - MXClipViewDelegate
-(void)clipViewMouseMoved:(NSEvent *)theEvent
{
    if (!self.clipView.haveSetClearColor)
    {
        self.clipView.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.clipView.haveSetClearColor = YES;
    }
    
    NSPoint currentPoint = [NSEvent mouseLocation];
    
    NSRect currentRect = CGRectZero;
    NSRect rectInScreen = [self.window convertRectFromScreen:currentRect];
    rectInScreen = [self.screen convertRectFromBacking:currentRect];
    //NSLog(@"%lf---%lf", currentRect.origin.x, rectInScreen.origin.x);
    [NSEvent mouseLocation];
    
    for (NSDictionary *dic in [MXClipScreenManager sharedInstance].arrayRect)
    {
        CGRect windowRect;
        CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)dic[(id) kCGWindowBounds], &windowRect);
        currentRect = [SnipUtil cgWindowRectToScreenRect:windowRect];
        if (CGRectContainsPoint(currentRect, currentPoint))
        {
            NSScreen *screen = [NSScreen currentScreenForMouseLocation];
            if (![screen isEqual:self.screen])
            {
                [[MXClipScreenManager sharedInstance] changeKeyWindowWithScreen:screen];
            }
            else
            {
                if (!self.window.isKeyWindow)
                {
                    [self.window makeKeyAndOrderFront:nil];
                }
            }
            
            NSRect rectInScreen = [self.window convertRectFromScreen:currentRect];
            self.lastWindowRect = rectInScreen;
            //NSLog(@"x:%lf, y:%lf",currentRect.origin.x, currentRect.origin.y);
            self.lastWindowNumber = [[dic objectForKey:@"kCGWindowNumber"] integerValue];
        }
        
        int layer = 0;
        CFNumberRef numberRef = (__bridge CFNumberRef) dic[(id) kCGWindowLayer];
        CFNumberGetValue(numberRef, kCFNumberSInt32Type, &layer);
        if (layer < 0) continue;
        if ([SnipUtil isPoint:currentPoint inRect:currentRect])
        {
            if (layer == 0)
            {
                NSScreen *screen = [NSScreen currentScreenForMouseLocation];
                if (![screen isEqual:self.screen])
                {
                    [[MXClipScreenManager sharedInstance] changeKeyWindowWithScreen:screen];
                }
                else
                {
                    if (!self.window.isKeyWindow)
                    {
                        [self.window makeKeyAndOrderFront:nil];
                    }
                }
                
                NSRect rectInScreen = [self.window convertRectFromScreen:currentRect];
                self.lastWindowRect = rectInScreen;
                self.lastWindowNumber = [[dic objectForKey:@"kCGWindowNumber"] integerValue];
                break;
            }
        }
    }
    
    [self.clipView setFrameForContentView:self.lastWindowRect];
}

-(void)clipViewClipCurrentWindow:(MXClipView*)clipView
{
    [self clipScreen];
}

-(void)clipViewClipFullScreen:(MXClipView*)clipView
{
    //[self clipScreen];
}

-(void)clipViewMouseDoubleClick:(MXClipView*)clipView
{
    [self clipScreen];
}

#pragma mark - MXClipToolbarViewControllerDelegate
- (void)clipToolbarViewControllerCliped:(MXClipToolbarViewController*)controller
{
    [self clipScreen];
}

- (void)clipToolbarViewControllerCancel:(MXClipToolbarViewController*)controller
{
    [self endCapture];
    
    if ([self.delegate respondsToSelector:@selector(clipWindowControllerDidCancel:)])
    {
        [self.delegate clipWindowControllerDidCancel:self];
    }
}

#pragma mark - Private Methods
- (void)clipScreen
{
    [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
    
    NSView *selectedView = self.clipView.contentView;
    NSRect frameRelativeToWindow = [selectedView convertRect:selectedView.bounds toView:nil];
    NSRect frameRelativeToScreen = [selectedView.window convertRectToScreen:frameRelativeToWindow];
    
    float screenHeight = [[[NSScreen screens] firstObject] frame].size.height;
    frameRelativeToScreen.origin.y = screenHeight - frameRelativeToScreen.size.height - frameRelativeToScreen.origin.y;
    
    NSMutableArray *exceptWinodwsArray = [NSMutableArray new];
    [exceptWinodwsArray addObject:@([self.clipView.window windowNumber])];
    if (self.clipView.onlyClipCurrentWindow && !CGSizeEqualToSize([NSScreen mainScreen].frame.size, self.lastWindowRect.size))
    {
        for (NSDictionary *dic in [MXClipScreenManager sharedInstance].arrayRect)
        {
            NSInteger windowNumber = [[dic objectForKey:@"kCGWindowNumber"] integerValue];
            if (self.lastWindowNumber != windowNumber)
            {
                [exceptWinodwsArray addObject:[dic objectForKey:@"kCGWindowNumber"]];
            }
        }
    }
    NSImage *image  = [NSImage imageRectangleScreen:NSInsetRect(frameRelativeToScreen,5,5) exceptWinodws:exceptWinodwsArray];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        
        NSWindow *window = self.clipView.cropBorderView.window;
        self.clipView.animator.contentFrame = NSMakeRect(0, 0, NSWidth([window frame]), NSHeight([window frame]));
    } completionHandler:^{
        
        if ([self.window isVisible])
        {
            [self.window orderOut:nil];
        }
        [NSEvent removeMonitor:self.eventMonitor];
        self.eventMonitor = nil;
        self.clipView = nil;
        
        if ([self.delegate respondsToSelector:@selector(clipWindowController:didClipedWithImage:)])
        {
            [self.delegate clipWindowController:self didClipedWithImage:image];
        }
    }];
}

@end

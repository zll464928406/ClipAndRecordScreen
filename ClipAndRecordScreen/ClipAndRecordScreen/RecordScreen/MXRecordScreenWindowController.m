//
//  MXRecordScreenWindowController.m
//  MoxtraDesktopAgent
//
//  Created by sunny on 2017/12/15.
//  Copyright © 2017年 moxtra. All rights reserved.
//

#import "MXRecordScreenWindowController.h"
#import "GKResizeableCropOverlayView.h"
#import "MXRecordToolbarWindowController.h"
#import "MXRecordToolbarViewController.h"
#import "MXRecordScreenManager.h"
#import "MXCaptureScreenSession.h"
#import "MXClipView.h"
#import "CircleCounterView.h"
#import "CircleDownCounter.h"

#import "SnipUtil.h"
#import "MXAlertBlocks.h"
#import "NSImage+Screenshot.h"
#import "NSScreen+PointConversion.h"

#define kShadyWindowLevel   (NSDockWindowLevel + 1000)
#define kCaptureScreenFrameRate            4.0

@interface MXRecordScreenWindowController () <MXClipViewDelegate, MXRecordToolbarViewControllerDelegate, MXRecordToolbarWindowControllerDelegate, MXCaptureScreenSessionDelegate, CircleCounterViewDelegate>

@property (nonatomic, strong) MXCaptureScreenSession *captureSession;

@property (nonatomic, strong) MXClipView *recordScreenView;
@property (nonatomic, strong) MXRecordToolbarWindowController *toolbarWindowController;
@property (nonatomic, strong) MXRecordToolbarViewController *toolbarViewController;

@property (nonatomic, strong) id eventMonitor;
@property (nonatomic, strong) NSMutableArray *shadeWindows;
@property (nonatomic, strong) NSScreen *selectedScreen;

@property (nonatomic, assign) NSRect lastWindowRect;
@property (nonatomic, assign) NSRect selectedRegion;

@property (nonatomic, strong) NSTimer *timerDuration;
@property (nonatomic, strong) NSString *recordFileName;

@end

@implementation MXRecordScreenWindowController
- (instancetype)initWithDelegate:(id<MXRecordScreenWindowControllerDelegate>) delegate
{
    self = [super init];
    if (self)
    {
        self.delegate = delegate;
        self.shadeWindows = [NSMutableArray array];
        
        self.captureSession = [[MXCaptureScreenSession alloc] init];
        self.captureSession.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    
}

#pragma mark - Public Methods
- (void)startRecorderScreen:(NSScreen*)screen
{
    self.screen = screen;
    
    self.window = [[MXClipWindow alloc] initWithContentRect:[screen frame] styleMask:NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO screen:screen];
    [self.window setLevel:kShadyWindowLevel];
    [self.shadeWindows addObject:self.window];
    self.recordScreenView = [[MXClipView alloc] initWithFrame:NSMakeRect(0, 0, screen.frame.size.width, screen.frame.size.height) type:MXClipViewRecordType];
    self.recordScreenView.delegate = self;
    self.recordScreenView.wantsLayer = YES;
    self.recordScreenView.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.4].CGColor;
    self.recordScreenView.haveSetClearColor = NO;
    self.window.contentView = self.recordScreenView;
    [self.window setFrame:screen.frame display:YES animate:NO];
    [self.window makeKeyAndOrderFront:nil];
    
    self.toolbarViewController = [[MXRecordToolbarViewController alloc] init];
    self.toolbarViewController.delegate = self;
    NSRect rect = NSMakeRect(0, 0, screen.frame.size.width, screen.frame.size.height);
    [self.recordScreenView showClipViewWithFrame:rect withToolbar:self.toolbarViewController.view];
    self.lastWindowRect = rect;
    self.selectedScreen = screen;
    
    // esc key pressed
    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSEventMaskKeyDown) handler:^(NSEvent *incomingEvent) {
        NSEvent *result = incomingEvent;
        if ([incomingEvent type] == NSEventTypeKeyDown && incomingEvent.keyCode == 53)
        {
            [self cleanup];
            if ([self.delegate respondsToSelector:@selector(recordScreenWindowControllerDidCancel:)])
            {
                [self.delegate recordScreenWindowControllerDidCancel:self];
            }
            
            [[NSCursor arrowCursor] set];
        }
        
        return result;
    }];
}

- (void)removeEventMonitor
{
    [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
}

- (void)cleanup
{
    if ([self.window isVisible])
    {
        [self.window orderOut:nil];
    }
    
    if (self.captureSession.status == CSStatusPaused || self.captureSession.status == CSStatusRecording)
    {
        [self.captureSession stopRecording];
    }
    
    [self.timerDuration invalidate];
    self.timerDuration = nil;
    
    [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
    
    self.recordScreenView = nil;
    self.toolbarViewController = nil;
}

#pragma mark - MXClipViewDelegate
-(void)clipViewMouseMoved:(NSEvent *)theEvent
{
    if (!self.recordScreenView.haveSetClearColor)
    {
        self.recordScreenView.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.recordScreenView.haveSetClearColor = YES;
    }
    
    NSPoint currentPoint = [NSEvent mouseLocation];
    NSRect currentRect = CGRectZero;
    
    for (NSDictionary *dic in [MXRecordScreenManager sharedInstance].arrayRect)
    {
        CGRect windowRect;
        CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)dic[(id) kCGWindowBounds], &windowRect);
        currentRect = [SnipUtil cgWindowRectToScreenRect:windowRect];
        if (CGRectContainsPoint(currentRect, currentPoint))
        {
            NSScreen *screen = [NSScreen currentScreenForMouseLocation];
            if (![screen isEqual:self.screen])
            {
                [[MXRecordScreenManager sharedInstance] changeKeyWindowWithScreen:screen];
            }
            else
            {
                if (!self.window.isKeyWindow)
                {
                    [self.window makeKeyAndOrderFront:nil];
                }
            }
            
            NSRect rectInScreen = [self.window convertRectFromScreen:currentRect];
//            NSLog(@"x:%lf, y:%lf",currentRect.origin.x, currentRect.origin.y);
            self.lastWindowRect = rectInScreen;
        }
        
        int layer = 0;
        CFNumberRef numberRef = (__bridge CFNumberRef) dic[(id) kCGWindowLayer];
        CFNumberGetValue(numberRef, kCFNumberSInt32Type, &layer);
        if (layer < 0) continue;
        if ([SnipUtil isPoint:currentPoint inRect:currentRect]) {
            if (layer == 0)
            {
                NSScreen *screen = [NSScreen currentScreenForMouseLocation];
                if (![screen isEqual:self.screen])
                {
                    [[MXRecordScreenManager sharedInstance] changeKeyWindowWithScreen:screen];
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
                
                break;
            }
        }
    }
    
    if (self.lastWindowRect.origin.x < 0)
    {
        CGPoint point = self.lastWindowRect.origin;
        CGSize size = self.lastWindowRect.size;
        
        self.lastWindowRect = NSMakeRect(0, point.y, size.width+point.x, size.height);
    }
    
    if (self.lastWindowRect.origin.y < 0)
    {
        CGPoint point = self.lastWindowRect.origin;
        CGSize size = self.lastWindowRect.size;
        
        self.lastWindowRect = NSMakeRect(point.x, 0, size.width, size.height+point.y);
    }
    
    
    [self.recordScreenView setFrameForContentView:self.lastWindowRect];
}

-(void)recordViewDidShowToolBar:(MXClipView*)clipView
{
    if ([self.delegate respondsToSelector:@selector(recordScreenWindowControllerDidSelectRegion:)])
    {
        [self.delegate recordScreenWindowControllerDidSelectRegion:self];
    }
}

#pragma mark - MXRecordToolbarViewControllerDelegate
- (void)recordToolbarViewControllerStartNote:(MXRecordToolbarViewController*)controller
{
    if ([self.delegate respondsToSelector:@selector(recordScreenWindowControllerRemoveEventMonitor:)])
    {
        [self.delegate recordScreenWindowControllerRemoveEventMonitor:self];
    }
    
    [self.shadeWindows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        NSWindow *window = obj;
        [window setIgnoresMouseEvents:YES];
    }];
    
    [controller.view.window makeFirstResponder:nil];
    NSView *myView = self.toolbarViewController.startNoteButton;
    
    [self.toolbarViewController.startNoteButton setHidden:YES];
    
    NSRect frameRelativeToWindow = [myView convertRect:myView.bounds toView:nil];
    NSRect frameRelativeToScreen = [myView.window convertRectToScreen:frameRelativeToWindow];
    
    self.recordScreenView.cropBorderView.hideHandleRect = YES;
    [self.recordScreenView.indicatorField setHidden:YES];
    self.recordScreenView.cropBorderView.borderColor = [NSColor colorWithDeviceRed:0.79 green:0.20 blue:0.08 alpha:1];
    
    self.toolbarWindowController = [[MXRecordToolbarWindowController alloc] init];
    self.toolbarWindowController.delegate = self;
    [self.toolbarWindowController.window setFrameOrigin:frameRelativeToScreen.origin];
    [self.toolbarWindowController.window setLevel:kShadyWindowLevel+1];
    [self.toolbarWindowController.window setBackgroundColor:[NSColor clearColor]];
    [self.toolbarWindowController.window setAlphaValue:1];
    [self.toolbarWindowController.window setOpaque:NO];
    [self.toolbarWindowController.window setHasShadow:NO];
    [self.toolbarWindowController.window makeKeyAndOrderFront:self];
    
    [self.toolbarWindowController changeToStatus:record_status_None];
    
    self.captureSession.exceptWinodwArray = @[@([controller.view.window windowNumber]),@([self.toolbarWindowController.window windowNumber])];
    
    {
        NSView *selectedView = self.recordScreenView.contentView;
        
        NSRect frameRelativeToWindow = [selectedView convertRect:selectedView.bounds toView:nil];
        NSRect frameRelativeToScreen = [selectedView.window convertRectToScreen:frameRelativeToWindow];
        self.selectedRegion = frameRelativeToScreen;
    }
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        self.recordScreenView.animator.overlayAlpha = 0.1;
    } completionHandler:^{
        
        [self.toolbarViewController.view removeFromSuperview];
        self.toolbarViewController = nil;
        [self startRecording];
    }];
}

#pragma mark- MXRecordToolbarWindowControllerDelegate
- (void)recordToolbarWindowControllerRecord:(MXRecordToolbarWindowController*)controller
{
    if (self.captureSession.status == CSStatusRecording)
    {
        [self.captureSession pauseRecording];
    }
    else if (self.captureSession.status == CSStatusPaused)
    {
        [self.captureSession resumeRecording];
    }
}

- (void)recordToolbarWindowControllerStop:(MXRecordToolbarWindowController*)controller
{
    [self stopRecording];
}

#pragma mark - CircleCounterViewDelegate
- (void)counterDownFinished:(CircleCounterView *)circleView
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        circleView.animator.alphaValue = 0.0f;
        [circleView.animator removeFromSuperview];
        context.duration = 0;
    } completionHandler:^{
        
        circleView.delegate = nil;
        
        self.timerDuration = [NSTimer timerWithTimeInterval:0.5
                                                     target:self
                                                   selector:@selector(timerDurationTimeOut:)
                                                   userInfo:nil
                                                    repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timerDuration forMode:NSDefaultRunLoopMode];
        
        [self.captureSession startRecording];
    }];
}

#pragma mark- MXCaptureScreenSessionDelegate
- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didReadyToRecordingToPath:(NSString*)path
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showCircleDownCounter];
    });
}

- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didStartRecordingToPath:(NSString*)path
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.toolbarWindowController changeToStatus:record_status_recording];
    });
}

- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didPauseRecordingToPath:(NSString*)path
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.toolbarWindowController changeToStatus:record_status_pause];
    });
}

- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didResumeRecordingToPath:(NSString*)path
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.toolbarWindowController changeToStatus:record_status_recording];
    });
}

- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didFinishRecordingToPath:(NSString*)path error:(CSErrorCode)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.timerDuration){
            [self.timerDuration invalidate];
            self.timerDuration = nil;
        }
        
        [self.recordScreenView removeFromSuperview];
        self.recordScreenView = nil;
        
        if ([self.window isVisible])
        {
            [self.window orderOut:nil];
        }
        
        [self.shadeWindows removeAllObjects];
        [self.toolbarWindowController close];
        self.toolbarWindowController = nil;
        
        BOOL saveTolocal = NO;
        if ((error == CSErrorMaximumFileSizeReached)) {
            
            [MXAlertBlocks showModleMessage:NSLocalizedString(@"reach the maximum file size", nil) title:@"Error"];
            saveTolocal = YES;
        }
        
        [self.delegate recordScreenWindowController:self finishRecordWithFileName:self.recordFileName saveToLocal:saveTolocal];
    });
}

- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession runtimeErrorDidOccur:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"record failed, reson=%@",[error localizedFailureReason]);
    });
}

- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession startWriteError:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"record failed, reson=%@",[error localizedFailureReason]);
        [captureSession stopRecording];
    });
}

#pragma mark - Private Methods
- (void)showCircleDownCounter
{
    int circleWidth = 200;
    if (circleWidth > MIN(NSWidth(self.recordScreenView.contentView.bounds), NSHeight(self.recordScreenView.contentView.bounds)))
    {
        circleWidth = MIN(NSWidth(self.recordScreenView.contentView.bounds), NSHeight(self.recordScreenView.contentView.bounds))/2;
    }
    CircleCounterView *circleCounterView = [CircleDownCounter showCircleDownWithSeconds:4.0f
                                                                                 onView:self.recordScreenView.contentView
                                                                               withSize:CGSizeMake(circleWidth, circleWidth)
                                                                                andType:CircleDownCounterTypeIntegerDecre];
    circleCounterView.delegate = self;
    circleCounterView.numberColor = [NSColor whiteColor];
    circleCounterView.numberFont = [NSFont fontWithName:@"Courier-Bold" size:60.0f];
    circleCounterView.circleColor = [NSColor whiteColor];
    circleCounterView.circleBorderWidth = 10.0f;
}
- (void)startRecording
{
    /* Create a recording file */
    NSString *fileName = [NSUUID UUID].UUIDString;
    char *screenRecordingFileName = strdup([[NSTemporaryDirectory() stringByAppendingPathComponent:fileName] fileSystemRepresentation]);
    if (screenRecordingFileName)
    {
        int fileDescriptor = mkstemp(screenRecordingFileName);
        if (fileDescriptor != -1)
        {
            NSString *filenameStr = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:screenRecordingFileName length:strlen(screenRecordingFileName)];
            
            self.recordFileName = [filenameStr stringByAppendingPathExtension:@"mov"];
            NSLog(@"record file path= %@, clip region = %@", self.recordFileName, NSStringFromRect(self.selectedRegion));
            // Starts recording to a given URL.
            self.captureSession.maximumFileSize = 1024*1014;
            self.captureSession.frameRate = kCaptureScreenFrameRate;
            [self.captureSession recordToPath:self.recordFileName withCropRect:self.selectedRegion forScreen:self.selectedScreen];
        }
        
        remove(screenRecordingFileName);
        free(screenRecordingFileName);
    }
}

- (void)stopRecording
{
    if(self.timerDuration)
    {
        [self.timerDuration invalidate];
        self.timerDuration = nil;
    }
    
    [self.window orderOut:nil];
    [self.recordScreenView removeFromSuperview];
    [self.captureSession stopRecording];
}

- (void)timerDurationTimeOut:(NSTimer *)timer
{
    int duration = [self.captureSession countRecordedDuration];
    
    if (duration >=0)
    {
        NSUInteger m = (duration / 60) % 60;
        NSUInteger s = duration % 60;
        
        NSString *formattedTime = [NSString stringWithFormat:@"%02lu:%02lu",(unsigned long)m,(unsigned long)s];
        NSString *recordDuration = [NSString stringWithFormat:@"%@s",formattedTime];
        self.toolbarWindowController.durationTextField.stringValue = recordDuration;
    }
    else
    {
        NSLog(@"get error record duration= %d",duration);
    }
}

@end

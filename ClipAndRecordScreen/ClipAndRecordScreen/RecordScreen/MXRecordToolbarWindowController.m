//
//  MXRecordToolbarWindowController.m
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 6/27/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//
#import <Quartz/Quartz.h>
#import "MXRecordToolbarWindowController.h"

@interface MXRecordToolbarWindowController ()

@property (strong) CABasicAnimation *freshAnimation;

@end

@implementation MXRecordToolbarWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.freshAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [self.freshAnimation setFromValue:[NSNumber numberWithFloat:1.0]];
    [self.freshAnimation setToValue:[NSNumber numberWithFloat:0.3]];
    [self.freshAnimation setDuration:0.5f];
    [self.freshAnimation setTimingFunction:[CAMediaTimingFunction
                                  functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [self.freshAnimation setAutoreverses:YES];
    [self.freshAnimation setRepeatCount:HUGE_VALF];
    
    [self.recordButton setEnabled:NO];
    [self.stopButton setEnabled:NO];
}

- (NSString*)windowNibName
{
    return @"MXRecordToolbarWindowController";
}

- (IBAction)recordButtonClick:(id)sender {
    
    [self.delegate recordToolbarWindowControllerRecord:self];
}

- (IBAction)stopButtonClick:(id)sender {
    [self.window setIsVisible:NO];
    [self.delegate recordToolbarWindowControllerStop:self];
}

- (void)changeToStatus:(RecordStatus)status
{
    switch (status) {
        case record_status_None:
        {
            [self.recordButton setEnabled:NO];
            [self.stopButton setEnabled:NO];
        }
            break;
        case record_status_recording:
        {
            [self.recordButton setEnabled:YES];
            self.recordButton.image = [NSImage imageNamed:@"pause"];
            self.recordButton.toolTip = NSLocalizedString(@"Pause", @"Pause");
            self.backgroundImageView.image = [NSImage imageNamed:@"record_control_bar"];
            
            [self.stopButton setEnabled:YES];
            self.stopButton.toolTip = NSLocalizedString(@"Stop", @"Stop");
            
            [self.recordButton.layer removeAnimationForKey:@"opacity"];
        }
            break;
         
        case record_status_pause:
        {
            self.recordButton.image = [NSImage imageNamed:@"restart"];
            self.recordButton.toolTip = NSLocalizedString(@"Restart", @"Restart");
            self.backgroundImageView.image = [NSImage imageNamed:@"black_bar"];
            
            [self.recordButton.layer addAnimation:self.freshAnimation forKey:@"opacity"];
        }
        default:
            break;
    }
}

@end

//
//  MXRecordToolbarWindowController.h
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 6/27/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
    record_status_None,
    record_status_recording,
    record_status_pause,
    record_status_Resume,
};
typedef NSUInteger RecordStatus;

@class MXRecordToolbarWindowController;

@protocol MXRecordToolbarWindowControllerDelegate <NSObject>

- (void)recordToolbarWindowControllerRecord:(MXRecordToolbarWindowController*)controller;
- (void)recordToolbarWindowControllerStop:(MXRecordToolbarWindowController*)controller;

@end

@interface MXRecordToolbarWindowController : NSWindowController

@property (weak) id<MXRecordToolbarWindowControllerDelegate> delegate;
@property (weak) IBOutlet NSButton *recordButton;
@property (weak) IBOutlet NSButton *stopButton;
@property (weak) IBOutlet NSTextField *durationTextField;
@property (weak) IBOutlet NSImageView *backgroundImageView;

- (IBAction)recordButtonClick:(id)sender;
- (IBAction)stopButtonClick:(id)sender;

- (void)changeToStatus:(RecordStatus)status;


@end

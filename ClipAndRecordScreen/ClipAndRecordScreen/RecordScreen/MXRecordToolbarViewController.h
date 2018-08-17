//
//  MXRecordToolbarViewController.h
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 6/27/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MXButton.h"

@class MXRecordToolbarViewController;

@protocol MXRecordToolbarViewControllerDelegate <NSObject>

- (void)recordToolbarViewControllerStartNote:(MXRecordToolbarViewController*)controller;

@end

@interface MXRecordToolbarViewController : NSViewController

@property (weak) id<MXRecordToolbarViewControllerDelegate> delegate;
@property (weak) IBOutlet MXButton *startNoteButton;
@property (weak) IBOutlet NSTextField *startNoteTextField;


- (IBAction)startNoteButtonClick:(id)sender;

@end

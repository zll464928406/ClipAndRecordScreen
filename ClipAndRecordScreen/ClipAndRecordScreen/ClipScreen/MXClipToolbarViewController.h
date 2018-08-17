//
//  MXClipToolbarViewController.h
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 6/27/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MXClipToolbarViewController;

@protocol MXClipToolbarViewControllerDelegate <NSObject>

- (void)clipToolbarViewControllerCancel:(MXClipToolbarViewController*)controller;
- (void)clipToolbarViewControllerCliped:(MXClipToolbarViewController*)controller;

@end

@interface MXClipToolbarViewController : NSViewController

@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *clipButton;

@property (weak) id<MXClipToolbarViewControllerDelegate> delegate;


@end

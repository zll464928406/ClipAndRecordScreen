//
//  MXRecordScreenWindowController.h
//  MoxtraDesktopAgent
//
//  Created by sunny on 2017/12/15.
//  Copyright © 2017年 moxtra. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MXClipWindow.h"

@class MXRecordScreenWindowController;

@protocol MXRecordScreenWindowControllerDelegate <NSObject>

- (void)recordScreenWindowController:(MXRecordScreenWindowController*)controller finishRecordWithFileName:(NSString *)fileName saveToLocal:(BOOL)saveTolocal;
- (void)recordScreenWindowControllerDidSelectRegion:(MXRecordScreenWindowController*)windowController;
- (void)recordScreenWindowControllerRemoveEventMonitor:(MXRecordScreenWindowController*)windowController;
- (void)recordScreenWindowControllerDidCancel:(MXRecordScreenWindowController*)windowController;


@end

@interface MXRecordScreenWindowController : NSWindowController

@property (nonatomic,weak) id<MXRecordScreenWindowControllerDelegate> delegate;
@property (nonatomic, strong) NSScreen *screen;

- (instancetype)initWithDelegate:(id<MXRecordScreenWindowControllerDelegate>) delegate;
- (void)startRecorderScreen:(NSScreen*)screen;
- (void)removeEventMonitor;
- (void)cleanup;

@end

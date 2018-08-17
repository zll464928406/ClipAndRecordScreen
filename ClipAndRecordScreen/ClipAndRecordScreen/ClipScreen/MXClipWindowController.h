//
//  MXClipWindowController.h
//  MoxtraClipDemo
//
//  Created by sunny on 2017/12/11.
//  Copyright © 2017年 moxtra. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MXClipWindow.h"

@class MXClipWindowController;

@protocol MXClipWindowControllerDelegate <NSObject>

- (void)clipWindowController:(MXClipWindowController*)windowController didClipedWithImage:(NSImage*)image;
- (void)clipWindowControllerDidCancel:(MXClipWindowController*)windowController;

@end

@interface MXClipWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic, weak) id<MXClipWindowControllerDelegate> delegate;
@property (nonatomic, strong) NSScreen *screen;

- (instancetype)initWithDelegate:(id<MXClipWindowControllerDelegate>)delegate;
- (void)startCaptureWithScreen:(NSScreen *)screen;
- (void)endCapture;

@end

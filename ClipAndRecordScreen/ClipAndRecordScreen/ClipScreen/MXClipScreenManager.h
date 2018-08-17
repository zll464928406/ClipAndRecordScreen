//
//  MXClipScreenManager.h
//  MoxtraDesktopAgent
//
//  Created by sunny on 2018/7/6.
//  Copyright © 2018年 moxtra. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface MXClipScreenManager : NSObject

@property (nonatomic, strong) NSMutableArray *arrayRect;
@property (nonatomic, assign) BOOL isWorking;

+ (instancetype)sharedInstance;
- (void)startCapture;
- (void)changeKeyWindowWithScreen:(NSScreen*)screen;
- (void)showUploadWindowToFront;
- (void)reset;

@end

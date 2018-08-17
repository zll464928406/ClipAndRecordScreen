//
//  MXRecordScreenManager.h
//  MoxtraDesktopAgent
//
//  Created by sunny on 2018/7/9.
//  Copyright © 2018年 moxtra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface MXRecordScreenManager : NSObject

@property (nonatomic, strong) NSMutableArray *arrayRect;
@property (nonatomic, assign) BOOL isWorking;

+ (instancetype)sharedInstance;
- (void)startRecordScreen;
- (void)changeKeyWindowWithScreen:(NSScreen*)screen;
- (void)showUploadWindowToFront;
- (void)reset;

@end

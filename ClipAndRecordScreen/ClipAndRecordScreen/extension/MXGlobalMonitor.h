//
//  MXGlobalMonitor.h
//  Moxtra
//
//  Created by Raymond Xu on 11/7/13.
//  Copyright (c) 2013 Mxotra. All rights reserved.
//

#import <Foundation/Foundation.h>


extern const NSString * kGlobalMonitorMonitorId;        //NSNumber uint32_t
extern const NSString * kGlobalMonitorMonitorName;      //NSString
extern const NSString * kGlobalMonitorAppId;            //NSNumber uint32_t
extern const NSString * kGlobalMonitorAppIcon;          //NSImage
extern const NSString * kGlobalMonitorAppName;          //NSImage

extern const NSString * kGlobalMonitorWinName;          //NSString
extern const NSString * kGlobalMonitorWinNumber;        //NSString NSInteger
extern const NSString * kGlobalMonitorWinFrame;         //NSValue   NSRect

@interface MXGlobalMonitor : NSObject

+ (NSArray *)monitorList;
+ (NSArray *)applicationList;
+ (NSRect)monitorFrame:(uint32_t)monitorId;
+ (NSArray *)windowsForPid:(uint32_t)pid;

@end

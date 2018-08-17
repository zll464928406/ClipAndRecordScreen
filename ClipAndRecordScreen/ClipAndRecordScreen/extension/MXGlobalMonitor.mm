//
//  MXGlobalMonitor.m
//  Moxtra
//
//  Created by Raymond Xu on 11/7/13.
//  Copyright (c) 2013 Mxotra. All rights reserved.
//
#import <IOKit/graphics/IOGraphicsLib.h>
#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/AppKit.h>
#import "MXGlobalMonitor.h"

#define     DSKE_MAX_MONITORS_SUPPORT		16
#define     DSKE_MAX_WINDOWS_SUPPORT		64

const NSString * kGlobalMonitorMonitorId = @"MonitorId";
const NSString * kGlobalMonitorMonitorName = @"MonitorName";
const NSString * kGlobalMonitorAppId = @"AppId";
const NSString * kGlobalMonitorAppName = @"AppName";
const NSString * kGlobalMonitorAppIcon = @"AppIcon";

const NSString * kGlobalMonitorWinName = @"WinName";
const NSString * kGlobalMonitorWinNumber = @"WinNumber";
const NSString * kGlobalMonitorWinFrame = @"WinFrame";

@implementation MXGlobalMonitor

+ (NSArray *)monitorList
{
    NSMutableArray *output = [NSMutableArray array];
    CGDirectDisplayID * displayList = new CGDirectDisplayID[DSKE_MAX_MONITORS_SUPPORT];
    uint32_t displayCount = 0;
    CGError error = CGGetActiveDisplayList(DSKE_MAX_MONITORS_SUPPORT, displayList, &displayCount);
    if(error == kCGErrorSuccess) {
        
        for (int i=0; i<displayCount; i++) {
            
            CGDirectDisplayID diplayId = displayList[i];
            
            NSString *screenName = nil;
            NSDictionary *deviceInfo = (__bridge_transfer NSDictionary *)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayList[i]), kIODisplayOnlyPreferredName);
            NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
            if ([localizedNames count] > 0) {
                screenName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
            }
            
            NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:diplayId],kGlobalMonitorMonitorId,
                                                                            screenName,kGlobalMonitorMonitorName,nil];
            [output addObject:dic];
        }
    }
    
    return output;
}

+ (NSArray *)applicationList
{
    NSMutableArray *output = [NSMutableArray array];
    
    NSMutableIndexSet *pidIndex = [NSMutableIndexSet indexSet];
    
    NSArray *windows = (__bridge_transfer NSArray*) CGWindowListCopyWindowInfo( kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    for(NSDictionary* winDict in windows)
    {
        NSString* appName = [winDict valueForKey:(__bridge NSString*)kCGWindowOwnerName];
        pid_t pid = (pid_t)[[winDict valueForKey:(__bridge NSString*)kCGWindowOwnerPID] intValue];
        NSNumber *windowAlpha = (NSNumber*)[winDict objectForKey:(__bridge NSString*)kCGWindowAlpha];
        
        if ([windowAlpha floatValue] == 0.0)
            continue;
        
        if (pid == getpid())
            continue;
        
        
        if(appName && ![appName isEqualTo:@"SystemUIServer"] && ![appName isEqualTo:@"Window Server"] && ![appName isEqualTo:@"Main Menu"] && ![appName isEqualTo:@"Dock"])
        {
            
            if (![pidIndex containsIndex:pid]) {
                
                NSRunningApplication* app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
                NSImage* icon = [app icon];
                
                NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:pid],kGlobalMonitorAppId,
                                     appName,kGlobalMonitorAppName,icon,kGlobalMonitorAppIcon,nil];
                
                [output addObject:dic];
                
                [pidIndex addIndex:pid];
            }
        }
    }

    return  output;
}

+ (NSRect)monitorFrame:(uint32_t)monitorId
{
    CGRect bounds = CGDisplayBounds(monitorId);
    
    return NSRectFromCGRect(bounds);
}

+ (NSArray *)windowsForPid:(uint32_t)pid
{
    NSMutableArray *output = [NSMutableArray array];
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    for (NSMutableDictionary* entry in (__bridge NSArray*)windowList)
    {
        NSString* ownerName = [entry objectForKey:(__bridge id)kCGWindowOwnerName];
        NSInteger ownerPID = [[entry objectForKey:(__bridge id)kCGWindowOwnerPID] integerValue];
        
        CFDictionaryRef  dic = (__bridge CFDictionaryRef)[entry valueForKey:(__bridge NSString*)kCGWindowBounds];
        CGRect windowRect = CGRectNull;
        CGRectMakeWithDictionaryRepresentation(dic,&windowRect);
        
        NSRect mainFrame = [[NSScreen mainScreen] frame];
        NSRect windowFrame = NSMakeRect(windowRect.origin.x, mainFrame.size.height-(windowRect.origin.y+windowRect.size.height), windowRect.size.width, windowRect.size.height);
        
        if (pid == ownerPID) {
            
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:ownerName,kGlobalMonitorWinName,[NSNumber numberWithInteger:ownerPID],kGlobalMonitorWinNumber,[NSValue valueWithRect:windowFrame],kGlobalMonitorWinFrame, nil];
            [output addObject:info];
        }
    }
    CFRelease(windowList);
    
    return output;
}
@end

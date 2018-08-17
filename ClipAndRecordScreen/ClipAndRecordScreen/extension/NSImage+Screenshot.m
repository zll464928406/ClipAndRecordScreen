//
//  NSImage+Screenshot.m
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 5/29/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import "NSImage+Screenshot.h"

@implementation NSImage (Screenshot)

+(NSImage*)imageFullScreen
{
    NSRect imageRect = NSZeroRect;
    CGImageRef screenshot = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly,
                                                    kCGNullWindowID, kCGWindowImageDefault);
    
    CGFloat displayScale = 1.f;
    if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)]) {
        displayScale = [NSScreen mainScreen].backingScaleFactor;
    }
    
    imageRect.size.height = CGImageGetHeight(screenshot) / displayScale;
    imageRect.size.width = CGImageGetWidth(screenshot) / displayScale;
    
    NSImage *image = [[NSImage alloc] initWithCGImage:screenshot size:imageRect.size];
    
    CGImageRelease(screenshot);
    
    return image;
}

+(NSImage*)imageMainFullScreen
{
    NSRect mainFrame = [[NSScreen mainScreen] frame];
    CGDirectDisplayID mainID = CGMainDisplayID();
    CGImageRef screenshot = CGDisplayCreateImage(mainID);
    NSImage *image = [[NSImage alloc] initWithCGImage:screenshot size:mainFrame.size];
    CGImageRelease(screenshot);
    
    return image;
}

+(NSImage*)imageMainScreenForRect:(NSRect)rect
{
    NSRect mainFrame = [[NSScreen mainScreen] frame];
    CGRect frame = CGRectMake(rect.origin.x, NSHeight(mainFrame)-NSHeight(rect)-NSMinY(rect), rect.size.width, rect.size.height);
    CGDirectDisplayID mainID = CGMainDisplayID();
    CGImageRef screenshot = CGDisplayCreateImageForRect(mainID,frame);
    NSImage *image = [[NSImage alloc] initWithCGImage:screenshot size:frame.size];
    CGImageRelease(screenshot);
    
    return image;
}

+(NSImage*)imageRectangleScreen:(NSRect)rect exceptWinodws:(NSArray*)windowArray
{
#if 0
    NSRect imageRect = NSZeroRect;
    float screenHeight = [[NSScreen mainScreen] frame].size.height;
    rect.origin.y = screenHeight - rect.size.height - rect.origin.y;
    
    CGImageRef screenshot = CGWindowListCreateImage(rect, kCGWindowListOptionOnScreenOnly,
                                                    kCGNullWindowID, kCGWindowImageDefault);
    
    CGFloat displayScale = 1.f;
    if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)]) {
        displayScale = [NSScreen mainScreen].backingScaleFactor;
    }
    
    imageRect.size.height = CGImageGetHeight(screenshot) / displayScale;
    imageRect.size.width = CGImageGetWidth(screenshot) / displayScale;
    
    NSImage *image = [[NSImage alloc] initWithCGImage:screenshot size:imageRect.size];
    
    return image;
#else
    
    CGRect rcRefresh = NSRectToCGRect(rect);
    
    if (!CGRectIsNull(rcRefresh)) {
        
        CFArrayRef onScreenWindows = CGWindowListCreate(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
        //pid_t myPid= getpid();
        CFMutableArrayRef desktopElements = CFArrayCreateMutableCopy(NULL, 0, onScreenWindows);
        for (long i = CFArrayGetCount(desktopElements) - 1; i >= 0; i--)
        {
            CGWindowID windowId = (CGWindowID)(uintptr_t)CFArrayGetValueAtIndex(desktopElements, i);
            [windowArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSNumber *objExceptWinodId = obj;
                if ([objExceptWinodId isKindOfClass:[NSNumber class]]) {
                    
                    CGWindowID exceptWinodw = [objExceptWinodId unsignedIntValue];
                    
                    if (windowId == exceptWinodw) {
                        CFArrayRemoveValueAtIndex(desktopElements, i);
                    }
                }
            }];
        }
        CGImageRef captureImage = CGWindowListCreateImageFromArray(rcRefresh, desktopElements, kCGWindowListOptionAll|kCGWindowImageNominalResolution);
        CFRelease(onScreenWindows);
        CFRelease(desktopElements);
			
        NSImage *image = [[NSImage alloc] initWithCGImage:captureImage size:rect.size];
        
        CGImageRelease(captureImage);
        
        return image;
    }
#endif
    return nil;
}
@end

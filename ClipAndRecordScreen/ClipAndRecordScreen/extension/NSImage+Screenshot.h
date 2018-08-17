//
//  NSImage+Screenshot.h
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 5/29/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Screenshot)

+(NSImage*)imageMainFullScreen;
+(NSImage*)imageMainScreenForRect:(NSRect)rect;

+(NSImage*)imageFullScreen;
+(NSImage*)imageRectangleScreen:(NSRect)rect exceptWinodws:(NSArray*)windowArray;

@end

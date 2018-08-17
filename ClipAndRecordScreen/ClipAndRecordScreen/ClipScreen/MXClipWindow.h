//
//  MXClipWindow.h
//  MoxtraClipDemo
//
//  Created by sunny on 2017/12/11.
//  Copyright © 2017年 moxtra. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MXClipWindowMouseEventDelegate <NSObject>

- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)mouseMoved:(NSEvent *)theEvent;

@end

@interface MXClipWindow : NSPanel

@property(weak) id <MXClipWindowMouseEventDelegate> mouseDelegate;

@end

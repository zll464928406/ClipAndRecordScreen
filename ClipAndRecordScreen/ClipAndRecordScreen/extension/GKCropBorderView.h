//
//  PTCropBorderView.h
//  GKImagePicker
//
//  Created by Patrick Thonhauser on 9/21/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GKCropBorderView : NSView

@property (nonatomic,readwrite, assign) BOOL hideHandleRect;
@property (nonatomic, readwrite, strong) NSColor *borderColor;

- (BOOL)isInResizeRect:(NSPoint)point;

@end

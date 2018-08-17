//
//  GKResizeableView.h
//  GKImagePicker
//
//  Created by Patrick Thonhauser on 9/21/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "GKCropBorderView.h"
#import "GKImageCropOverlayView.h"
#import "GKToolbarView.h"

typedef struct {
    int widhtMultiplyer;
    int heightMultiplyer;
    int xMultiplyer;
    int yMultiplyer;
}GKResizeableViewBorderMultiplyer;

typedef enum {
    CorpRectNoneMode = 0,
    CorpRectResizeMode,
    CorpRectMoveMode,
}GKImageCropMode;

@protocol ResizeableCropOverlayViewDelegate;

@interface GKResizeableCropOverlayView : GKImageCropOverlayView

@property (nonatomic, strong) NSView* contentView;
@property (nonatomic, strong, readonly) GKCropBorderView *cropBorderView;
@property (nonatomic, strong) NSTextField* indicatorField;
@property (nonatomic, strong, readwrite) NSView *toolbarView;
@property (nonatomic, assign, readwrite) GKImageCropMode corpRectMode;
@property (nonatomic, assign, readwrite) BOOL menuVisible;
@property (nonatomic, assign, readwrite) NSRect contentFrame;
@property (nonatomic, assign, readwrite) CGFloat overlayAlpha;
@property (nonatomic, strong, readwrite) NSProgressIndicator *progressIndicator;

@property(nonatomic, weak)id<ResizeableCropOverlayViewDelegate> delegate;

/**
 call this method to create a resizable crop view
 @param frame
 @param initial crop size
 @return crop view instance
 */
-(id)initWithFrame:(CGRect)frame andInitialContentRect:(CGRect)contentRect;
-(id)initWithFrame:(CGRect)frame andInitialContentSize:(CGSize)contentSize;
-(id)initWithFrame:(CGRect)frame andProcessId:(pid_t)pid;

- (void)showCropOverlayWithFrame:(NSRect)initialSelectionRect withToolbar:(NSView*)view;
- (void)showOrHiddenProgressIndicator:(BOOL)show;

@end


@protocol ResizeableCropOverlayViewDelegate<NSObject>

@optional

//-(void)resizeableCropOverlayView:(GKResizeableCropOverlayView *)resizeableCropOverlayView  didSelectedRect:(NSRect)rect;
-(void)resizeableCropOverlayViewCancleSelected:(GKResizeableCropOverlayView*)resizeableCropOverlayView;

@end
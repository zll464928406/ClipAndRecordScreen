//
//  MXClipView.h
//  MoxtraClipDemo
//
//  Created by sunny on 2017/12/11.
//  Copyright © 2017年 moxtra. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GKImageCropOverlayView.h"
#import "GKCropBorderView.h"

@class MXClipView;

typedef enum : NSUInteger {
    MXClipViewClipType,
    MXClipViewRecordType,
} MXClipViewType;

@protocol MXClipViewDelegate <NSObject>
@optional

-(void)clipViewClipCurrentWindow:(MXClipView*)clipView;
-(void)clipViewClipFullScreen:(MXClipView*)clipView;
-(void)clipViewMouseDoubleClick:(MXClipView*)clipView;
-(void)clipViewCancleSelected:(MXClipView*)clipView;
-(void)clipViewMouseMoved:(NSEvent *)theEvent;
-(void)recordViewDidShowToolBar:(MXClipView*)clipView;

@end

@interface MXClipView : GKImageCropOverlayView

@property (nonatomic,weak) id<MXClipViewDelegate> delegate;
@property (nonatomic, strong, readonly) NSView* contentView;
@property (nonatomic, strong, readonly) GKCropBorderView *cropBorderView;
@property (nonatomic, strong, readwrite) NSTextField* indicatorField;
@property (nonatomic, assign, readwrite) NSRect contentFrame;
@property (nonatomic, assign, readwrite) CGFloat overlayAlpha;
@property (nonatomic, assign, readwrite) BOOL onlyClipCurrentWindow;
@property (nonatomic, assign, readwrite) MXClipViewType type;
@property (nonatomic, assign, readwrite) BOOL haveSetClearColor;

- (instancetype)initWithFrame:(NSRect)frame type:(MXClipViewType)type;
- (void)showClipViewWithFrame:(NSRect)initialSelectionRect withToolbar:(NSView*)view;
- (void)setFrameForContentView:(NSRect)rect;

@end

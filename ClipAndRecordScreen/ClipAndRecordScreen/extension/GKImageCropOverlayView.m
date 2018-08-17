//
//  GKImageCropOverlayView.m
//  GKImagePicker
//
//  Created by Georg Kitz on 6/1/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKImageCropOverlayView.h"
#import "NSValue+CGPoint.h"

@interface GKImageCropOverlayView ()
//@property (nonatomic, strong) UIToolbar *toolbar;
@end

@implementation GKImageCropOverlayView

#pragma mark -
#pragma Getter/Setter

@synthesize cropSize;
//@synthesize toolbar;

#pragma mark -
#pragma Overriden

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
        //self.userInteractionEnabled = YES;
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (void)drawRect:(CGRect)rect{
    
    CGFloat toolbarSize = 0;//UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 54;

    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame) - toolbarSize;
    
    CGFloat heightSpan = floor(height / 2 - self.cropSize.height / 2);
    CGFloat widthSpan = floor(width / 2 - self.cropSize.width  / 2);
    
    //fill outer rect
    [[NSColor colorWithDeviceRed:0. green:0. blue:0. alpha:0.5] set];
    NSRectFill(self.bounds);
    
    //fill inner border
    [[NSColor colorWithDeviceRed:1. green:1. blue:1. alpha:0.5] set];
    NSRectFill(CGRectMake(widthSpan - 2, heightSpan - 2, self.cropSize.width + 4, self.cropSize.height + 4));
    
    //fill inner rect
    [[NSColor clearColor] set];
    NSRectFill(CGRectMake(widthSpan, heightSpan, self.cropSize.width, self.cropSize.height));
    
    
    
    if (heightSpan > 30 ){//&& (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        
        [[NSColor whiteColor] set];
        /*
        [NSLocalizedString(@"GKImoveAndScale", @"") drawInRect:CGRectMake(10, (height - heightSpan) + (heightSpan / 2 - 20 / 2) , width - 20, 20) 
                                                   withFont:[NSFont boldSystemFontOfSize:20]
                                              lineBreakMode:NSLineBreakByTruncatingTail 
                                                  alignment:NSTextAlignmentCenter];
         */
        
    }
}

@end


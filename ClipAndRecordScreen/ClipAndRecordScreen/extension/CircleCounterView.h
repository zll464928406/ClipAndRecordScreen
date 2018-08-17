//
//  CircleCounterView.h
//  CircleCountDown
//
//  Created by Haoxiang Li on 11/25/11.
//  Copyright (c) 2011 DEV. All rights reserved.
//


#import <AppKit/AppKit.h>
@class CircleCounterView;

@protocol CircleCounterViewDelegate <NSObject>

- (void)counterDownFinished:(CircleCounterView *)circleView;

@end

@interface CircleCounterView : NSView {
    
    //< Different with mTimeInterval, this one decides how long a circle finished. 1 seconds by default
    float mCircleTimeInterval;
    
    NSColor *mNumberColor;      //< Black, By Default
    NSFont *mNumberFont;        //< Courier-Bold 20, By Default

    NSColor *mCircleColor;      //< Black, By Default
    CGFloat mCircleBorderWidth; //< 6 pixels, By Default
    
    float mTimeInSeconds;       //< 20, By Default
    float mTimeInterval;        //< 1,  By Default
    NSString *mTimeFormatString; //< For Example, @"%.0f", @"%.1f"
    
    BOOL mIsRunning;
    int mCircleSegs;
    
    BOOL mCircleIncre;          //< Default NO, the circle is drawed incrementally, otherwise decrementally
}

@property (nonatomic, assign) id<CircleCounterViewDelegate> delegate;

@property (nonatomic, assign) BOOL circleIncre;

@property (nonatomic, retain) NSColor *numberColor;
@property (nonatomic, retain) NSFont *numberFont;

@property (nonatomic, retain) NSColor *circleColor;
@property (nonatomic, assign) CGFloat circleBorderWidth;
@property (nonatomic, assign) float circleTimeInterval; 

- (void)startWithSeconds:(float)seconds;
- (void)startWithSeconds:(float)seconds andInterval:(float)interval;
- (void)startWithSeconds:(float)seconds andInterval:(float)interval andTimeFormat:(NSString *)timeFormat;
- (void)stop;

@end

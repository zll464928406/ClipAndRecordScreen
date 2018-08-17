//
//  CircleCounterView.m
//  CircleCountDown
//
//  Created by Haoxiang Li on 11/25/11.
//  Copyright (c) 2011 DEV. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CircleCounterView.h"

#define kCircleSegs 30

@interface CircleCounterView ()
@property (nonatomic, retain) NSString *timeFormatString;

- (void)setup;
- (void)update:(id)sender;
- (void)updateTime:(id)sender;

@end

@implementation CircleCounterView
@synthesize numberColor = mNumberColor;
@synthesize numberFont = mNumberFont;
@synthesize circleColor = mCircleColor;
@synthesize circleBorderWidth = mCircleBorderWidth;
@synthesize timeFormatString = mTimeFormatString;
@synthesize circleIncre = mCircleIncre;
@synthesize circleTimeInterval = mCircleTimeInterval;

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}
                      
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc {
    
    self.numberFont = nil;
    self.numberColor = nil;
    self.circleColor = nil;
    self.circleBorderWidth = 0;
    self.timeFormatString = nil;
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    float radius = CGRectGetWidth(rect)/2.0f - self.circleBorderWidth/2.0f - 45.0f;
    float angleOffset = M_PI_2;
    
    CGContextSetLineWidth(context, self.circleBorderWidth);
    CGContextBeginPath(context);
    if (self.circleIncre)
    {
        CGContextAddArc(context, 
                        CGRectGetMidX(rect), CGRectGetMidY(rect),
                        radius, 
                        -angleOffset, 
                        (mCircleSegs + 1)/(float)kCircleSegs*M_PI*2 - angleOffset, 
                        0);
    }
    else
    {
        CGContextAddArc(context, 
                        CGRectGetMidX(rect), CGRectGetMidY(rect),
                        radius, 
                        (mCircleSegs + 1)/(float)kCircleSegs*M_PI*2 - angleOffset, 
                        2*M_PI - angleOffset, 
                        0);
    }
    CGContextSetStrokeColorWithColor(context, self.circleColor.CGColor);
    CGContextStrokePath(context);
    
    CGContextSetLineWidth(context, 1.0f);
    [self.numberColor set];
    NSString *numberText = [NSString stringWithFormat:self.timeFormatString, mTimeInSeconds];
    NSDictionary *textDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica Neue Bold" size:45.0f],NSFontAttributeName,self.numberColor, NSForegroundColorAttributeName,nil];
    CGSize sz = [numberText sizeWithAttributes:textDic];
    
    [numberText drawInRect:NSInsetRect(rect, (CGRectGetWidth(rect) - sz.width)/2.0f, (CGRectGetHeight(rect) - sz.height)/2.0f) withAttributes:textDic];
}

- (void)setup {
    
    mIsRunning = NO;
    
    //< Default Parameters
    self.numberColor = [NSColor blackColor];
    self.numberFont = [NSFont fontWithName:@"Courier-Bold" size:20.0f];
    self.circleColor = [NSColor blackColor];
    self.circleBorderWidth = 6;
    self.timeFormatString = @"%.0f";
    self.circleIncre = NO;
    self.circleTimeInterval = 1.0f;
        
    mTimeInSeconds = 20;
    mTimeInterval = 1;
    mCircleSegs = 0;
    
    [self setWantsLayer:YES];
    
    self.layer.backgroundColor = [NSColor colorWithDeviceWhite:0.1f alpha:0.5f].CGColor;
    self.layer.cornerRadius = 10.0f;
}

#pragma mark - Public Methods
- (void)startWithSeconds:(float)seconds andInterval:(float)interval andTimeFormat:(NSString *)timeFormat {
    self.timeFormatString = timeFormat;
    [self startWithSeconds:seconds andInterval:interval];
}

- (void)startWithSeconds:(float)seconds andInterval:(float)interval {
    if (interval > seconds)
    {
        mTimeInterval = seconds/10.0f;
    }
    else
    {
        mTimeInterval = interval;
    }
    [self startWithSeconds:seconds];
}

- (void)startWithSeconds:(float)seconds {
    if (seconds > 0)
    {
        mTimeInSeconds = seconds;
        mIsRunning = YES;
        mCircleSegs = 0;
        [self update:nil];
        [self updateTime:nil];
    }
}

- (void)stop {
    mIsRunning = NO;
}

#pragma mark - Private Methods
- (void)update:(id)sender {
    if (mIsRunning)
    {
        mCircleSegs = (mCircleSegs + 1) % kCircleSegs;
        //if (mTimeInSeconds == -1)
        if (fabs(mTimeInSeconds) < 1e-4)
        {
            //< Finished
            mCircleSegs = (kCircleSegs - 1);
            mTimeInSeconds = 0;
            if(self.superview)
                [self.delegate counterDownFinished:self];
        }
        else
        {
            [NSTimer scheduledTimerWithTimeInterval:self.circleTimeInterval/kCircleSegs
                                             target:self
                                           selector:@selector(update:) 
                                           userInfo:nil
                                            repeats:NO];
        }
        [self setNeedsDisplay:YES];
    }
}

- (void)updateTime:(id)sender {
    if (mIsRunning)
    {
        mTimeInSeconds -= mTimeInterval;
        //if (mTimeInSeconds == -1)
        if (fabs(mTimeInSeconds) < 1e-4)
        {
            //< Finished
            mCircleSegs = (kCircleSegs - 1);
            mTimeInSeconds = 0;
            
            [self setNeedsDisplay:YES];
            if(self.superview)
                [self.delegate counterDownFinished:self];
        }
        else
        {            
            [NSTimer scheduledTimerWithTimeInterval:mTimeInterval
                                             target:self 
                                           selector:@selector(updateTime:)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
}

@end

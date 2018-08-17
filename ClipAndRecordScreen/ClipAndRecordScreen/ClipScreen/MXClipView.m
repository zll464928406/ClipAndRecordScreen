//
//  MXClipView.m
//  MoxtraClipDemo
//
//  Created by sunny on 2017/12/11.
//  Copyright © 2017年 moxtra. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MXClipView.h"
#import "NSString+Extension.h"
#import "NSValue+CGPoint.h"

#define kBorderCorrectionValue 6

#define kContentViewMinWidth  64
#define kContentViewMinHeight 64

#define kToolbarWidth    268
#define kToolbarHeight    30
#define kToolbarEdge     20

typedef struct {
    int widhtMultiplyer;
    int heightMultiplyer;
    int xMultiplyer;
    int yMultiplyer;
}ContentViewBorderMultiplyer;

typedef enum {
    MXClipViewDragNoneMode = 0,
    MXClipViewDragResizeMode,
    MXClipViewDragMoveMode,
}MXClipViewDragMode;

typedef enum {
    MXClipViewStateNone = 0,
    MXClipViewStateMouseDown,
    MXClipViewStateMouseDrag,
    MXClipViewStateMouseUp,
}MXClipViewState;

@interface MXClipView ()

@property (nonatomic, strong) NSTrackingArea *trackingArea;

@property (nonatomic, strong) NSView* contentView;
@property (nonatomic, strong) GKCropBorderView *cropBorderView;
@property (nonatomic, strong) NSView *toolbarView;

@property (nonatomic, assign) CGRect contentRect;
@property (nonatomic, assign) CGPoint theAnchor;
@property (nonatomic, assign) CGPoint startPoint;

@property (nonatomic, assign) MXClipViewDragMode dragMode;
@property (nonatomic, assign) MXClipViewState clipState;
@property (nonatomic, assign) ContentViewBorderMultiplyer resizeMultiplyer;


@property (nonatomic, assign) NSPoint rectBeginPoint;
@property (nonatomic, assign) NSPoint rectEndPoint;
@property (nonatomic, assign) BOOL rectDrawing;
@property (nonatomic, assign) CGRect lastContentRect;
@property (nonatomic, strong) NSDate *lastDate;

@end

@implementation MXClipView

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    NSRect rect = self.contentRect;
    self.contentView.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width,rect.size.height);
    self.cropBorderView.frame = CGRectMake(rect.origin.x - kBorderCorrectionValue, rect.origin.y - kBorderCorrectionValue, rect.size.width + kBorderCorrectionValue*2, rect.size.height + kBorderCorrectionValue*2);
    
    self.contentFrame = self.cropBorderView.frame;
}

- (instancetype)initWithFrame:(NSRect)frame type:(MXClipViewType)type
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.overlayAlpha = 0.5;
        self.onlyClipCurrentWindow = YES;
        self.type = type;
    }
    return self;
}

- (void)updateTrackingAreas
{
    NSArray *trackingAreas = self.trackingAreas;
    [trackingAreas enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSTrackingArea* trackingArea = obj;
        
        [self removeTrackingArea:trackingArea];
    }];
    
    if (self.trackingArea)
    {
        [self removeTrackingArea:self.trackingArea];
    }
    
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options: (NSTrackingMouseMoved | NSTrackingActiveAlways) owner:self userInfo:nil];
    [self addTrackingArea:self.trackingArea];
}

#pragma mark - Public Methods
- (void)showClipViewWithFrame:(NSRect)initialSelectionRect withToolbar:(NSView*)view
{
    self.clipState = MXClipViewStateNone;
    self.contentRect = initialSelectionRect;
    self.toolbarView = view;
    [self.toolbarView setAlphaValue:0];
    [self setUpUI];
}

- (void)setFrameForContentView:(NSRect)rect
{
    self.contentRect = rect;
    self.contentView.frame = rect;
    self.cropSize = self.contentView.frame.size;
    [_cropBorderView setFrame:CGRectMake(rect.origin.x - kBorderCorrectionValue, rect.origin.y - kBorderCorrectionValue, rect.size.width + kBorderCorrectionValue*2, rect.size.height + kBorderCorrectionValue*2)];
    self.contentFrame = _cropBorderView.frame;
    
    [self _resetToolBarFrame];
    
    NSFont *font = [NSFont systemFontOfSize:12];
    NSString *indicator = NSLocalizedString(@"Press ESC key to exit", @"");
    NSSize size = [indicator caculateSizeWithFontType:font];
    
    float width = size.width+10;
    float height = size.height;
    
    NSRect indicatorFrame = NSMakeRect(NSMaxX(_cropBorderView.frame)-width, NSMinY(_cropBorderView.frame)-height+5, width, height);
    [self.indicatorField setFrame:indicatorFrame];
}

#pragma mark - Mouse Action
- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2)
    {
        if ([self.delegate respondsToSelector:@selector(clipViewMouseDoubleClick:)])
        {
            [self.delegate clipViewMouseDoubleClick:self];
        }
        return;
    }
    
    if (self.clipState == MXClipViewStateNone)
    {
        self.lastDate = [NSDate date];
        self.clipState = MXClipViewStateMouseDown;
        NSPoint mouseLocation = [NSEvent mouseLocation];
        mouseLocation = [self fetchLocationFromScreen:mouseLocation];
        if (NSPointInRect(mouseLocation, self.frame)) {
            self.rectBeginPoint = mouseLocation;
        }
    }
    
    [self addSubview:_cropBorderView];
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint pointToBoardView = [self convertPoint:point toView:self.cropBorderView];
    
    if (NSPointInRect(point, _contentView.frame) && ![self.cropBorderView isInResizeRect:pointToBoardView]) {
        self.dragMode = MXClipViewDragMoveMode;
    }
    else if(NSPointInRect(point, _cropBorderView.frame)) {
        
        self.theAnchor = [self _calcuateWhichBorderHandleIsTheAnchorPointFromHere:[self convertPoint:point toView:self.cropBorderView]];
        self.dragMode = MXClipViewDragResizeMode;
        [self _fillMultiplyer];
    }
    else {
        self.dragMode = MXClipViewDragNoneMode;
    }
    
    [self _resetToolBarFrame];
    [self _resetIndicatorField];
    
    self.startPoint = point;
    [super mouseDown:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
    if ([self.delegate respondsToSelector:@selector(clipViewCancleSelected:)]) {
        [self.delegate clipViewCancleSelected:self];
    }
    [super rightMouseUp:theEvent];
}

-(void)mouseUp:(NSEvent *)event
{
    if (!self.toolbarView.superview)
    {
        if (self.clipState == MXClipViewStateMouseDown && self.type == MXClipViewClipType)
        {
            if ([self.delegate respondsToSelector:@selector(clipViewClipCurrentWindow:)])
            {
                [self.delegate clipViewClipCurrentWindow:self];
            }
        }
        else
        {
            [self addSubview:self.toolbarView];
            
            NSPoint point = NSMakePoint([NSScreen mainScreen].frame.size.width*0.5, [NSScreen mainScreen].frame.size.height*0.5);
            [self.toolbarView setFrameOrigin:point];
            
            NSTimeInterval timeDuration = [[NSDate date] timeIntervalSinceDate:self.lastDate];
            if (timeDuration < 0.5
                && self.contentRect.size.width < kContentViewMinWidth
                && self.contentRect.size.height < kContentViewMinHeight)
            {
                [self setFrameForContentView:self.lastContentRect];
            }
            
            CGFloat yPoint = _cropBorderView.frame.origin.y+10;
            NSPoint toolbarPoint = NSMakePoint(NSMidX(_cropBorderView.frame) - NSWidth(self.toolbarView.bounds)/2,yPoint);
            NSRect rect = NSMakeRect(toolbarPoint.x, yPoint, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
            
            
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.5;
                [self.toolbarView setFrame:rect];
                if (self.toolbarView.alphaValue == 0)
                {
                    [self.toolbarView.animator setAlphaValue:1];
                    if ([self.delegate respondsToSelector:@selector(recordViewDidShowToolBar:)])
                    {
                        [self.delegate recordViewDidShowToolBar:self];
                    }
                }
                
            } completionHandler:^{
                
            }];
        }
    }
    if (self.clipState == MXClipViewStateMouseDrag)
    {
        if (self.contentRect.size.width < kContentViewMinWidth)
        {
            [self setFrameForContentView:NSMakeRect(self.contentRect.origin.x, self.contentRect.origin.y, kContentViewMinWidth, self.contentRect.size.height)];
        }
        if (self.contentRect.size.height < kContentViewMinHeight)
        {
            [self setFrameForContentView:NSMakeRect(self.contentRect.origin.x, self.contentRect.origin.y, self.contentRect.size.width, kContentViewMinHeight)];
        }
    }
    
    if (CGRectEqualToRect(self.contentRect, [NSScreen mainScreen].frame))
    {
        if ([self.delegate respondsToSelector:@selector(clipViewClipFullScreen:)])
        {
            [self.delegate clipViewClipFullScreen:self];
        }
    }
    
    self.clipState = MXClipViewStateMouseUp;
    [super mouseUp:event];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    self.onlyClipCurrentWindow = NO;
    if (self.clipState == MXClipViewStateMouseDown || self.clipState == MXClipViewStateMouseDrag)
    {
        self.clipState = MXClipViewStateMouseDrag;
        self.rectEndPoint = [self fetchLocationFromScreen:[NSEvent mouseLocation]];
        CGFloat x = MIN(self.rectEndPoint.x, self.rectBeginPoint.x);
        CGFloat y = MIN(self.rectEndPoint.y, self.rectBeginPoint.y);
        CGFloat width = fabs(self.rectEndPoint.x - self.rectBeginPoint.x);
        CGFloat height = fabs(self.rectEndPoint.y - self.rectBeginPoint.y);
        
        [self setFrameForContentView:NSMakeRect(x, y, width, height)];
        
        return;
    }
    
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (self.dragMode == MXClipViewDragMoveMode) {
        [self _moveWithTouchPoint:NSPointToCGPoint(point)];
    }
    else if(self.dragMode == MXClipViewDragResizeMode) {
        
        [self _resizeWithTouchPoint:NSPointToCGPoint(point)];
    }
    
    [self _resetToolBarFrame];
    [self _resetIndicatorField];
    
    [super mouseDragged:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    if (self.clipState == MXClipViewStateNone)
    {
        if ([self.delegate respondsToSelector:@selector(clipViewMouseMoved:)])
        {
            [self.delegate clipViewMouseMoved:theEvent];
            self.lastContentRect = self.contentRect;
        }
    }
    
    [super mouseMoved:theEvent];
}


#pragma mark - Private Methods
- (void)setUpUI
{
    NSRect rect = self.contentRect;
    self.contentView = [[NSView alloc] initWithFrame:rect];
    self.contentView.wantsLayer = YES;
    self.contentView.layer.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"clipBackground"]].CGColor;
    self.cropSize = self.contentView.frame.size;
    [self addSubview:self.contentView];
    
    self.cropBorderView = [[GKCropBorderView alloc] initWithFrame:CGRectMake(rect.origin.x - kBorderCorrectionValue, rect.origin.y - kBorderCorrectionValue, rect.size.width + kBorderCorrectionValue*2, rect.size.height + kBorderCorrectionValue*2)];
    
    self.contentFrame = self.cropBorderView.frame;
    
    [self _resetToolBarFrame];
    //    [self addSubview:self.toolbarView];
    
    NSFont *font = [NSFont systemFontOfSize:12];
    NSString *indicator = NSLocalizedString(@"Press ESC key to exit", @"");
    NSSize size = [indicator caculateSizeWithFontType:font];
    
    float width = size.width+10;
    float height = size.height;
    
    NSRect indicatorFrame = NSMakeRect(NSMaxX(_cropBorderView.frame)-width, NSMinY(_cropBorderView.frame)-height+5, width, height);
    self.indicatorField = [[NSTextField alloc] initWithFrame:indicatorFrame];
    [self addSubview:self.indicatorField];
    
    self.indicatorField.stringValue = indicator;
    self.indicatorField.textColor = [NSColor whiteColor];
    self.indicatorField.backgroundColor = [NSColor clearColor];
    self.indicatorField.font = font;
    self.indicatorField.alphaValue = 0.8;
    [self.indicatorField setEditable:NO];
    [self.indicatorField setBordered:NO];
}

- (void)_resetToolBarFrame
{
    CGFloat yPoint = _cropBorderView.frame.origin.y+10;
    
    NSPoint toolbarPoint = NSMakePoint(NSMidX(_cropBorderView.frame) - NSWidth(self.toolbarView.bounds)/2,yPoint);
    [self.toolbarView setFrameOrigin:toolbarPoint];
}

- (void)_resetIndicatorField
{
    NSFont *font = [NSFont systemFontOfSize:12];
    NSString *indicator = self.indicatorField.stringValue;
    NSSize size = [indicator caculateSizeWithFontType:font];
    
    float width = size.width+10;
    float height = size.height;
    
    if (NSWidth(_cropBorderView.frame) >= width) {
        [self.indicatorField setHidden:NO];
        [self.indicatorField setFrame:NSMakeRect(NSMaxX(_cropBorderView.frame)-width, NSMinY(_cropBorderView.frame)-height+5, width, height)];
    }
    else {
        [self.indicatorField setHidden:YES];
    }
    
}

-(CGPoint)_calcuateWhichBorderHandleIsTheAnchorPointFromHere:(CGPoint)anchorPoint{
    NSMutableArray* allHandles = [self _getAllCurrentHandlePositions];
    
    CGFloat closest = 3000;
    NSValue* theRealAnchor = nil;
    for (NSValue* value in allHandles){
        
        //Pythagoras is watching you :-)
        CGPoint currentPoint = [value CGPointValue];
        CGFloat xDist = (currentPoint.x - anchorPoint.x);
        CGFloat yDist = (currentPoint.y - anchorPoint.y);
        CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
        
        closest = distance < closest ? distance : closest;
        theRealAnchor = closest == distance ? value : theRealAnchor;
    }
    
    return [theRealAnchor CGPointValue];
}

-(CGFloat)_calcuateDistanceOfTwoPoints:(CGPoint)point1 :(CGPoint)point2
{
    CGFloat xDist = (point1.x - point2.x);
    CGFloat yDist = (point1.y - point2.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

-(NSMutableArray*)_getAllCurrentHandlePositions{
    
    NSMutableArray* a = [NSMutableArray new];
    //
    //again starting with the upper left corner and then following the rect clockwise
    CGPoint currentPoint = CGPointMake(0, 0);
    
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width / 2, 0);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width, 0);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width, _cropBorderView.bounds.size.height / 2);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width , _cropBorderView.bounds.size.height);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(_cropBorderView.bounds.size.width / 2, _cropBorderView.bounds.size.height);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(0, _cropBorderView.bounds.size.height);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    currentPoint = CGPointMake(0, _cropBorderView.bounds.size.height / 2);
    [a addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    return a;
}

-(void)_moveWithTouchPoint:(CGPoint)point{
    CGFloat x = _cropBorderView.frame.origin.x + point.x - _startPoint.x;
    CGFloat y = _cropBorderView.frame.origin.y + point.y - _startPoint.y;
    
    [self _resetFramesToThisOne:CGRectMake(x, y, _cropBorderView.frame.size.width, _cropBorderView.frame.size.height)];
    _startPoint = point;
}

-(void)_resizeWithTouchPoint:(CGPoint)point{
    //This is the place where all the magic happends prevent goint offscreen...
    CGFloat border = kBorderCorrectionValue*2;
    point.x = point.x < border ? border : point.x;
    point.y = point.y < border ? border : point.y;
    point.x = point.x > self.superview.bounds.size.width - border ? point.x = self.superview.bounds.size.width - border : point.x;
    point.y = point.y > self.superview.bounds.size.height - border ? point.y = self.superview.bounds.size.height - border : point.y;
    
    CGFloat heightChange = (point.y - self.startPoint.y) * _resizeMultiplyer.heightMultiplyer;
    CGFloat widthChange = (self.startPoint.x - point.x) * _resizeMultiplyer.widhtMultiplyer;
    CGFloat xChange = -1 * widthChange * _resizeMultiplyer.xMultiplyer;
    CGFloat yChange = -1 * heightChange * _resizeMultiplyer.yMultiplyer;
    
    CGRect newFrame =  CGRectMake(_cropBorderView.frame.origin.x + xChange, _cropBorderView.frame.origin.y + yChange, _cropBorderView.frame.size.width + widthChange, _cropBorderView.frame.size.height + heightChange);
    
    newFrame = [self _preventBorderFrameFromGettingTooSmall:newFrame];
    
    [self _resetFramesToThisOne:newFrame];
    _startPoint = point;
}

-(CGRect)_preventBorderFrameFromGettingTooSmallOrTooBig:(CGRect)newFrame{
    CGFloat toolbarSize = 0;
    
    if (newFrame.size.width < kContentViewMinWidth) {
        newFrame.size.width = _cropBorderView.frame.size.width;
        newFrame.origin.x = _cropBorderView.frame.origin.x;
    }
    if (newFrame.size.height < kContentViewMinHeight) {
        newFrame.size.height = _cropBorderView.frame.size.height;
        newFrame.origin.y = _cropBorderView.frame.origin.y;
    }
    
    if (newFrame.origin.x < 0){
        newFrame.size.width = _cropBorderView.frame.size.width + (_cropBorderView.frame.origin.x - self.superview.bounds.origin.x);
        newFrame.origin.x = 0;
    }
    
    if (newFrame.origin.y < 0){
        newFrame.size.height = _cropBorderView.frame.size.height + (_cropBorderView.frame.origin.y - self.superview.bounds.origin.y);;
        newFrame.origin. y = 0;
    }
    
    if (newFrame.size.width + newFrame.origin.x > self.frame.size.width)
        newFrame.size.width = self.frame.size.width - _cropBorderView.frame.origin.x;
    
    if (newFrame.size.height + newFrame.origin.y > self.frame.size.height - toolbarSize)
        newFrame.size.height = self.frame.size.height  - _cropBorderView.frame.origin.y - toolbarSize;
    return newFrame;
}

-(CGRect)_preventBorderFrameFromGettingTooSmall:(CGRect)newFrame{
    if (newFrame.size.width < kContentViewMinWidth) {
        newFrame.size.width = _cropBorderView.frame.size.width;
        newFrame.origin.x = _cropBorderView.frame.origin.x;
    }
    if (newFrame.size.height < kContentViewMinHeight) {
        newFrame.size.height = _cropBorderView.frame.size.height;
        newFrame.origin.y = _cropBorderView.frame.origin.y;
    }
    
    return newFrame;
}

-(void)_resetFramesToThisOne:(CGRect)frame{
    _cropBorderView.frame = frame;
    _contentView.frame = CGRectInset(frame, kBorderCorrectionValue, kBorderCorrectionValue);
    self.contentFrame = _cropBorderView.frame;
    self.cropSize = _contentView.frame.size;
    [self setNeedsDisplay:YES];
    [_cropBorderView setNeedsDisplay:YES];
}

-(void)_fillMultiplyer{
    //-1 left, 0 middle, 1 right
    _resizeMultiplyer.heightMultiplyer =  (_theAnchor.y == 0 ? -1 : (_theAnchor.y == _cropBorderView.bounds.size.height) ? 1 : 0);
    //-1 up, 0 middle, 1 down
    _resizeMultiplyer.widhtMultiplyer = (_theAnchor.x == 0 ? 1 : (_theAnchor.x == _cropBorderView.bounds.size.width) ? -1 : 0);
    // 1 left, 0 middle, 0 right
    _resizeMultiplyer.xMultiplyer = (_theAnchor.x == 0 ? 1 : 0);
    // 1 up, 0 middle, 0 down
    _resizeMultiplyer.yMultiplyer = (_theAnchor.y == 0 ? 1 : 0);
}

- (NSPoint)fetchLocationFromScreen:(NSPoint)point
{
    NSRect rect = NSMakeRect(point.x, point.y, 0, 0);
    NSPoint location = [self.window convertRectFromScreen:rect].origin;
    
    return location;
}

#pragma mark -
#pragma drawing
- (void)drawRect:(NSRect)dirtyRect{
    
    [super drawRect:dirtyRect];
    
    //fill outer rect
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:self.overlayAlpha] set];
    NSRectFill(self.bounds);
    
    //fill inner rect
    [[NSColor clearColor] set];
    NSRectFill(self.contentView.frame);
}

- (void)setOverlayAlpha:(CGFloat)overlayAlpha
{
    _overlayAlpha = overlayAlpha;
    [self setNeedsDisplay:YES];
}

- (void)setContentFrame:(NSRect)contentFrame
{
    _contentFrame = contentFrame;
    self.cropBorderView.frame = contentFrame;
    self.contentView.frame = NSInsetRect(contentFrame,kBorderCorrectionValue,kBorderCorrectionValue);
    
    [self _resetToolBarFrame];
    [self _resetIndicatorField];
    
    [self setNeedsDisplay:YES];
}

+ (id)defaultAnimationForKey:(NSString *)key
{
    if ([key isEqualToString:@"contentFrame"]) {
        return [CABasicAnimation animation];
    }
    else if([key isEqualToString:@"overlayAlpha"]) {
        return [CABasicAnimation animation];
    }
    
    return [super defaultAnimationForKey:key];
}

@end

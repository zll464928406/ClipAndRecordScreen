//
//  GKResizeableView.m
//  GKImagePicker
//
//  Created by Patrick Thonhauser on 9/21/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKResizeableCropOverlayView.h"
#import "GKCropBorderView.h"
#import "NSValue+CGPoint.h"
#import "MXGlobalMonitor.h"
#import "NSString+Extension.h"
#import <QuartzCore/QuartzCore.h>

#define kBorderCorrectionValue 6

#define kToolbarWidth    268
#define kToolbarHeight    30
#define kToolbarEdge     20

@interface GKResizeableCropOverlayView(){
    CGSize _initialContentSize;
    CGRect _initialContentRect;
    pid_t   _initialPid;
    NSTrackingArea* _trackingArea;
    NSArray *_winodwArray;
    CGPoint _theAnchor;
    CGPoint _startPoint;
    GKResizeableViewBorderMultiplyer _resizeMultiplyer;
}

-(void)_addContentViews;
-(CGPoint)_calcuateWhichBorderHandleIsTheAnchorPointFromHere:(CGPoint)anchorPoint;
-(NSMutableArray*)_getAllCurrentHandlePositions;
-(void)_resizeWithTouchPoint:(CGPoint)point;
-(void)_fillMultiplyer;
-(CGRect)_preventBorderFrameFromGettingTooSmallOrTooBig:(CGRect)newFrame;

@end

@implementation GKResizeableCropOverlayView

@synthesize contentView = _contentView;
@synthesize cropBorderView = _cropBorderView;
@synthesize corpRectMode = _corpRectMode;
@synthesize menuVisible = menuVisible_;
@synthesize toolbarView = _toolbarView;
@synthesize progressIndicator = _progressIndicator;

@synthesize delegate  = delegate_;

#pragma mark -
#pragma Overriden

-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    //CGFloat toolbarSize = 0;//UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 54;
    _contentView.frame = CGRectMake(_initialContentRect.origin.x/*self.bounds.size.width / 2 - _initialContentSize.width  / 2*/  , _initialContentRect.origin.y/*(self.bounds.size.height - toolbarSize) / 2 - _initialContentSize.height / 2*/ , _initialContentRect.size.width,_initialContentRect.size.height/*_initialContentSize.width, _initialContentSize.height*/);
    _cropBorderView.frame = CGRectMake(_initialContentRect.origin.x/*self.bounds.size.width / 2 - _initialContentSize.width  / 2*/ - kBorderCorrectionValue, _initialContentRect.origin.y/*(self.bounds.size.height - toolbarSize) / 2 - _initialContentSize.height / 2*/ - kBorderCorrectionValue, _initialContentRect.size.width/*_initialContentSize.width*/ + kBorderCorrectionValue*2, _initialContentRect.size.height/*_initialContentSize.height*/ + kBorderCorrectionValue*2);
    
    self.contentFrame = _cropBorderView.frame;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.overlayAlpha = 0.5;
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame andInitialContentRect:(CGRect)contentRect{
    
    self = [super initWithFrame:frame];
    if (self) {
        _initialContentRect = contentRect;
        [self _addContentViews];
    }
    return self;
    
}

-(id)initWithFrame:(CGRect)frame andInitialContentSize:(CGSize)contentSize{
    
    self = [super initWithFrame:frame];
    if (self) {
        _initialContentSize = contentSize;
        [self _addContentViews];
    }
    return self;
    
}

-(id)initWithFrame:(CGRect)frame andProcessId:(pid_t)pid
{
    self = [super initWithFrame:frame];
    if (self) {
        _initialPid = pid;
        
        _winodwArray = [MXGlobalMonitor windowsForPid:pid];
        if (_winodwArray.count>0) {
            NSDictionary *dic =[_winodwArray objectAtIndex:0];
            _initialContentRect = [[dic objectForKey:kGlobalMonitorWinFrame] CGRectValue];
            [self _addContentViews];
            
            NSTrackingAreaOptions trackingOptions =
            NSTrackingMouseMoved | NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited |
            NSTrackingActiveInActiveApp;
            // note: NSTrackingActiveAlways flags turns off the cursor updating feature
            
            _trackingArea = [[NSTrackingArea alloc]
                              initWithRect: [self bounds] // in our case track the entire view
                              options: trackingOptions
                              owner: self
                              userInfo: nil];
            [self addTrackingArea: _trackingArea];
        }
       
    }
    return self;
}

- (void)dealloc
{
    
}

- (void)showCropOverlayWithFrame:(NSRect)initialSelectionRect withToolbar:(NSView*)view;
{    
    _initialContentRect = initialSelectionRect;
    self.toolbarView = view;
    [self _addContentViews];
}

- (void)showOrHiddenProgressIndicator:(BOOL)show
{
    if (show) {
//        CGFloat x= NSMidX(self.cropBorderView.frame);
        NSRect frame = NSMakeRect(NSMidX(self.cropBorderView.frame) - 8.0f, NSMidY(self.cropBorderView.frame) - 8.0f,16, 16);
        self.progressIndicator = [[NSProgressIndicator alloc] initWithFrame:frame];
        [self.progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
        [self.progressIndicator startAnimation:self];
        [self.progressIndicator sizeToFit];
        [self addSubview:self.progressIndicator];

    }
    else {
        [self.progressIndicator stopAnimation:nil];
        [self.progressIndicator removeFromSuperview];
        self.progressIndicator = nil;
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    NSPoint pointToBoardView = [self convertPoint:point toView:self.cropBorderView];
    if (NSPointInRect(point, _contentView.frame) && ![self.cropBorderView isInResizeRect:pointToBoardView]) {
        self.corpRectMode = CorpRectMoveMode;
    }
    else if(NSPointInRect(point, _cropBorderView.frame)) {
        
        _theAnchor = [self _calcuateWhichBorderHandleIsTheAnchorPointFromHere:[self convertPoint:point toView:_cropBorderView]];
        self.corpRectMode = CorpRectResizeMode;
        [self _fillMultiplyer];
    }
    else {
        self.corpRectMode = CorpRectNoneMode;
    }
    
    //[_toolbarView setFrame:NSMakeRect(NSMidX(_cropBorderView.frame) - kToolbarWidth/2, _cropBorderView.frame.origin.y-kToolbarHeight+kBorderCorrectionValue-kToolbarEdge, kToolbarWidth, kToolbarHeight)];
    
    //NSPoint toolbarPoint = NSMakePoint(NSMidX(_cropBorderView.frame) - NSWidth(self.toolbarView.bounds)/2, _cropBorderView.frame.origin.y-NSHeight(self.toolbarView.bounds));
    //[self.toolbarView setFrameOrigin:toolbarPoint];
    
    [self _resetToolBarFrame];
    [self _resetIndicatorField];
    
    _startPoint = point;
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
    if ([self.delegate respondsToSelector:@selector(resizeableCropOverlayViewCancleSelected:)]) {
        
        [self.delegate resizeableCropOverlayViewCancleSelected:self];
    }
    
    //[self.window orderOut:nil];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if (self.corpRectMode == CorpRectMoveMode) {
        [self _moveWithTouchPoint:NSPointToCGPoint(point)];
    }
    else if(self.corpRectMode == CorpRectResizeMode) {
        
        [self _resizeWithTouchPoint:NSPointToCGPoint(point)];
    }
    
    //NSPoint toolbarPoint = NSMakePoint(NSMidX(_cropBorderView.frame) - NSWidth(self.toolbarView.bounds)/2, _cropBorderView.frame.origin.y-NSHeight(self.toolbarView.bounds));
    //[self.toolbarView setFrameOrigin:toolbarPoint];
    [self _resetToolBarFrame];
    [self _resetIndicatorField];
    //[_toolbarView setFrame:NSMakeRect(NSMidX(_cropBorderView.frame) - kToolbarWidth/2, _cropBorderView.frame.origin.y-kToolbarHeight+kBorderCorrectionValue-kToolbarEdge, kToolbarWidth, kToolbarHeight)];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    //NSLog(@"......");
}
#pragma mark -
#pragma private

-(void)_addContentViews{
    //CGFloat toolbarSize = 0;//UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 54;

    _contentView = [[NSView alloc] initWithFrame:CGRectMake(_initialContentRect.origin.x/*self.bounds.size.width / 2 - _initialContentSize.width  / 2*/  , _initialContentRect.origin.y/*(self.bounds.size.height - toolbarSize) / 2 - _initialContentSize.height / 2*/ ,_initialContentRect.size.width /*_initialContentSize.width*/, _initialContentRect.size.height/*_initialContentSize.height*/)];
    
    [_contentView setWantsLayer:YES];
    _contentView.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.cropSize = _contentView.frame.size;
    [self addSubview:_contentView];
   // NSLog(@"x: %f y: %f %f", CGRectGetMinX(_contentView.frame), CGRectGetMinY(_contentView.frame), self.bounds.size.width);
    
    _cropBorderView = [[GKCropBorderView alloc] initWithFrame:CGRectMake(_initialContentRect.origin.x/*self.bounds.size.width / 2 - _initialContentSize.width  / 2*/ - kBorderCorrectionValue, _initialContentRect.origin.y/*(self.bounds.size.height - toolbarSize) / 2 - _initialContentSize.height / 2*/ - kBorderCorrectionValue, _initialContentRect.size.width/*_initialContentSize.width*/ + kBorderCorrectionValue*2, _initialContentRect.size.height/*_initialContentSize.height*/ + kBorderCorrectionValue*2)];
    [self addSubview:_cropBorderView];
    
    self.contentFrame = _cropBorderView.frame;
    
    //NSPoint toolbarPoint = NSMakePoint(NSMidX(_cropBorderView.frame) - NSWidth(self.toolbarView.bounds)/2, _cropBorderView.frame.origin.y-NSHeight(self.toolbarView.bounds));
    //[self.toolbarView setFrameOrigin:toolbarPoint];
    [self _resetToolBarFrame];
    [self addSubview:self.toolbarView];
    
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
    //This is the place where all the magic happends
    //prevent goint offscreen...
    CGFloat border = kBorderCorrectionValue*2;
    point.x = point.x < border ? border : point.x;
    point.y = point.y < border ? border : point.y;
    point.x = point.x > self.superview.bounds.size.width - border ? point.x = self.superview.bounds.size.width - border : point.x;
    point.y = point.y > self.superview.bounds.size.height - border ? point.y = self.superview.bounds.size.height - border : point.y;
    
    CGFloat heightChange = (point.y - _startPoint.y) * _resizeMultiplyer.heightMultiplyer;
    CGFloat widthChange = (_startPoint.x - point.x) * _resizeMultiplyer.widhtMultiplyer;
    CGFloat xChange = -1 * widthChange * _resizeMultiplyer.xMultiplyer;
    CGFloat yChange = -1 * heightChange * _resizeMultiplyer.yMultiplyer;
    
    CGRect newFrame =  CGRectMake(_cropBorderView.frame.origin.x + xChange, _cropBorderView.frame.origin.y + yChange, _cropBorderView.frame.size.width + widthChange, _cropBorderView.frame.size.height + heightChange);
    
    newFrame = [self _preventBorderFrameFromGettingTooSmall:newFrame];
    
    [self _resetFramesToThisOne:newFrame];
    _startPoint = point;
}

-(CGRect)_preventBorderFrameFromGettingTooSmallOrTooBig:(CGRect)newFrame{
    CGFloat toolbarSize = 0;//UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 54;

    if (newFrame.size.width < 64) {
        newFrame.size.width = _cropBorderView.frame.size.width;
        newFrame.origin.x = _cropBorderView.frame.origin.x;
    }
    if (newFrame.size.height < 64) {
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
    if (newFrame.size.width < 64) {
        newFrame.size.width = _cropBorderView.frame.size.width;
        newFrame.origin.x = _cropBorderView.frame.origin.x;
    }
    if (newFrame.size.height < 64) {
        newFrame.size.height = _cropBorderView.frame.size.height;
        newFrame.origin.y = _cropBorderView.frame.origin.y;
    }
    
    return newFrame;
}

- (void)_resetToolBarFrame
{
    CGFloat yPoint = _cropBorderView.frame.origin.y+10;
    
//    if (yPoint<=0) {
//        yPoint = _cropBorderView.frame.origin.y + _cropBorderView.frame.size.height;
//    }
    
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
    //NSPoint toolbarPoint = NSMakePoint(NSMidX(_cropBorderView.frame) - NSWidth(self.toolbarView.bounds)/2, _cropBorderView.frame.origin.y-NSHeight(self.toolbarView.bounds));
    //[self.toolbarView setFrameOrigin:toolbarPoint];
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

#pragma mark - selection & Delete actions for menu-
- (void)keyDown:(NSEvent *)theEvent
{
    
}

@end

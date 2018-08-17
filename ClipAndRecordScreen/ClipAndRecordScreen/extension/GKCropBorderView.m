//
//  PTCropBorderView.m
//  GKImagePicker
//
//  Created by Patrick Thonhauser on 9/21/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKCropBorderView.h"
#import "NSValue+CGPoint.h"
#import "NSColor+Moxtra.h"

#define kNumberOfBorderHandles 8
#define kHandleDiameter 10
#define kSmallHandleDiameter 6


@interface GKCropBorderView()
{
    NSMutableArray *_handleTrackRectArray;
    NSRect _contentTrackRect;
    BOOL _beDragging;
}

-(NSMutableArray*)_calculateAllNeededHandleRects;

@end

@implementation GKCropBorderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [NSColor clearColor].CGColor;
        self.borderColor = [NSColor colorWithDeviceRed:0.0 green:130.0/255 blue:213.0/255 alpha:0.85];
        
        _handleTrackRectArray = [NSMutableArray array];
        [self updateTrackingAreas];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSCursor arrowCursor] set];
}

#pragma mark -
#pragma drawing
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    NSColor *borderColor = [NSColor moxtraBrandingColor];
    
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSetStrokeColorWithColor(ctx, self.borderColor.CGColor);
    CGContextSetLineWidth(ctx, 1.0f);
    CGContextAddRect(ctx, CGRectMake(kHandleDiameter / 2, kHandleDiameter / 2, rect.size.width - kHandleDiameter, rect.size.height - kHandleDiameter));
    CGContextStrokePath(ctx);
    
    if (!self.hideHandleRect) {
        NSMutableArray* handleRectArray = [self _calculateAllNeededHandleRects];
        for (NSValue* value in handleRectArray){
            CGRect currentHandleRect = [value CGRectValue];
            
            //CGContextSetRGBFillColor(ctx, 0.0, 130.0/255, 213.0/255, 0.85);
            CGContextSetRGBFillColor(ctx, borderColor.redComponent, borderColor.greenComponent, borderColor.blueComponent, 0.85);
            CGContextFillEllipseInRect(ctx, currentHandleRect);
        }
        
        handleRectArray = [self _calculateAllNeededSmallHandleRects];
        for (NSValue* value in handleRectArray){
            CGRect currentHandleRect = [value CGRectValue];
            
            CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 0.95);
            CGContextFillEllipseInRect(ctx, currentHandleRect);
        }
    }
    
}

-(void)updateTrackingAreas
{
    NSArray *trackAreaArray = [self trackingAreas];
    [trackAreaArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSTrackingArea *trakArea = obj;
        [self removeTrackingArea:trakArea];
    }];
    
    if (!self.hideHandleRect) {
        [_handleTrackRectArray setArray:[self _calculateAllNeededHandleTrackRects]];
        _contentTrackRect = NSMakeRect(kHandleDiameter, kHandleDiameter , self.frame.size.width - 2*kHandleDiameter, self.frame.size.height - 2*kHandleDiameter);
        
        NSTrackingAreaOptions opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp);
        for (NSValue* value in _handleTrackRectArray){
            CGRect currentHandleRect = [value CGRectValue];
            
            
            NSTrackingArea *trackingArea = [ [NSTrackingArea alloc] initWithRect:currentHandleRect
                                                          options:opts
                                                            owner:self
                                                         userInfo:nil];
            [self addTrackingArea:trackingArea];
            
        }
    
        NSTrackingArea *trackingArea = [ [NSTrackingArea alloc] initWithRect:_contentTrackRect
                                                                     options:opts
                                                                       owner:self
                                                                    userInfo:nil];
        
        [self addTrackingArea:trackingArea];
        
    }
    
   
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    _beDragging = YES;
    [[self window] disableCursorRects];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    _beDragging = NO;
   
    
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if (![self isInResizeRect:point] ){
        
        [[self window] enableCursorRects];
        [[self window] resetCursorRects];
        [[NSCursor openHandCursor] set];
    }
        
    
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    _beDragging = YES;
    
//    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//    if (NSPointInRect(point, _contentTrackRect)) {
//        [[NSCursor closedHandCursor] set];
//    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if (!self.hideHandleRect ) {
        
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        [_handleTrackRectArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CGRect currentHandleRect = [obj CGRectValue];
            
            if (NSPointInRect(point, currentHandleRect)) {
                
                if (idx == 0 ||idx == 4) {
                    
                    NSString *cursorName = @"resizenortheastsouthwest";
                    NSString *cursorPath = [@"/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Resources/cursors" stringByAppendingPathComponent:cursorName];
                    NSImage *image = [[NSImage alloc] initByReferencingFile:[cursorPath stringByAppendingPathComponent:@"cursor.pdf"]];
                    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[cursorPath stringByAppendingPathComponent:@"info.plist"]];
                    NSCursor *cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint([[info valueForKey:@"hotx"] doubleValue], [[info valueForKey:@"hoty"] doubleValue])];
                    [cursor set];
                }
                else if (idx == 1 || idx == 5) {
                    
                    [[NSCursor resizeUpDownCursor] set];
                }
                else if (idx == 2 || idx == 6) {
                    
                    NSString *cursorName = @"resizenorthwestsoutheast";
                    NSString *cursorPath = [@"/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Resources/cursors" stringByAppendingPathComponent:cursorName];
                    NSImage *image = [[NSImage alloc] initByReferencingFile:[cursorPath stringByAppendingPathComponent:@"cursor.pdf"]];
                    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[cursorPath stringByAppendingPathComponent:@"info.plist"]];
                    NSCursor *cursor = [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint([[info valueForKey:@"hotx"] doubleValue], [[info valueForKey:@"hoty"] doubleValue])];
                    [cursor set];
                }
                else if (idx == 3 || idx == 7) {
                    
                    [[NSCursor resizeLeftRightCursor] set];
                }
            }
            
        }];
        
        if (NSPointInRect(point, _contentTrackRect)) {
            if (_beDragging) {
                [[NSCursor closedHandCursor] set];
            }
            else {
                [[NSCursor openHandCursor] set];
            }
        }
    }
}

- (void)resetCursorRects
{
    [super resetCursorRects];
    if(_beDragging) {
        [self addCursorRect:_contentTrackRect cursor:[NSCursor closedHandCursor]];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if (!_beDragging) {
        [[NSCursor arrowCursor] set];
    }
}

- (void)mouseMoved:(NSEvent *)theEvent
{
}

- (void)setBorderColor:(NSColor *)borderColor
{
    _borderColor = borderColor;
    
    [self setNeedsDisplay:YES];
}

- (void)setHideHandleRect:(BOOL)hideHandleRect
{
    _hideHandleRect = hideHandleRect;
    
    [self updateTrackingAreas];
    [self setNeedsDisplay:YES];
}

- (BOOL)isInResizeRect:(NSPoint)point
{
    __block BOOL isInResizeRect = NO;
    [_handleTrackRectArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGRect currentHandleRect = [obj CGRectValue];
        
        if (NSPointInRect(point, currentHandleRect)) {
            isInResizeRect = YES;
        }
    }];
    
    return isInResizeRect;
}
#pragma mark -
#pragma private

-(NSMutableArray*)_calculateAllNeededHandleTrackRects {
    
    NSMutableArray* a = [NSMutableArray new];
    //starting with the upper left corner and then following clockwise
    CGRect currentRect = CGRectMake(0, 0, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width / 2 - kHandleDiameter / 2, 0, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width - kHandleDiameter, 0 , kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    //upper row done
    currentRect = CGRectMake(self.frame.size.width - kHandleDiameter, self.frame.size.height / 2 - kHandleDiameter / 2, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width - kHandleDiameter, self.frame.size.height - kHandleDiameter, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width / 2 - kHandleDiameter / 2, self.frame.size.height - kHandleDiameter, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(0, self.frame.size.height - kHandleDiameter, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    //now back up again
    currentRect = CGRectMake(0, self.frame.size.height / 2 - kHandleDiameter / 2, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];

    return a;
}
-(NSMutableArray*)_calculateAllNeededHandleRects{
    
    NSMutableArray* a = [NSMutableArray new];
    //starting with the upper left corner and then following clockwise
    CGRect currentRect = CGRectMake(0, 0, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width / 2 - kHandleDiameter / 2, 0, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width - kHandleDiameter, 0 , kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    //upper row done
    currentRect = CGRectMake(self.frame.size.width - kHandleDiameter, self.frame.size.height / 2 - kHandleDiameter / 2, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width - kHandleDiameter, self.frame.size.height - kHandleDiameter, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width / 2 - kHandleDiameter / 2, self.frame.size.height - kHandleDiameter, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(0, self.frame.size.height - kHandleDiameter, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    //now back up again
    currentRect = CGRectMake(0, self.frame.size.height / 2 - kHandleDiameter / 2, kHandleDiameter, kHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    return a;
}

-(NSMutableArray*)_calculateAllNeededSmallHandleRects{
    
    NSMutableArray* a = [NSMutableArray new];
    //starting with the upper left corner and then following clockwise
    CGRect currentRect = CGRectMake(kHandleDiameter / 2 - kSmallHandleDiameter /2, kHandleDiameter / 2 - kSmallHandleDiameter /2, kSmallHandleDiameter, kSmallHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width / 2 - kSmallHandleDiameter / 2, kHandleDiameter / 2 - kSmallHandleDiameter /2, kSmallHandleDiameter, kSmallHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width - kHandleDiameter / 2 - kSmallHandleDiameter /2, kHandleDiameter / 2 - kSmallHandleDiameter /2 , kSmallHandleDiameter, kSmallHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    //upper row done
    currentRect = CGRectMake(self.frame.size.width - kHandleDiameter / 2 - kSmallHandleDiameter /2, self.frame.size.height / 2 - kSmallHandleDiameter / 2, kSmallHandleDiameter, kSmallHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width - kHandleDiameter / 2 - kSmallHandleDiameter /2, self.frame.size.height - kHandleDiameter / 2 - kSmallHandleDiameter /2, kSmallHandleDiameter, kSmallHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(self.frame.size.width / 2 - kSmallHandleDiameter / 2, self.frame.size.height - kHandleDiameter / 2 - kSmallHandleDiameter /2, kSmallHandleDiameter, kSmallHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    currentRect = CGRectMake(kHandleDiameter / 2 - kSmallHandleDiameter /2, self.frame.size.height - kHandleDiameter / 2 - kSmallHandleDiameter /2, kSmallHandleDiameter, kSmallHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    //now back up again
    currentRect = CGRectMake(kHandleDiameter / 2 - kSmallHandleDiameter /2, self.frame.size.height / 2 - kSmallHandleDiameter / 2, kSmallHandleDiameter, kSmallHandleDiameter);
    [a addObject:[NSValue valueWithCGRect:currentRect]];
    
    return a;
}
@end

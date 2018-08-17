//
//  NSValue+CGPoint.m
//  Moxtra
//
//  Created by Raymond Xu on 11/8/13.
//  Copyright (c) 2013 Mxotra. All rights reserved.
//

#import "NSValue+CGPoint.h"

@implementation NSValue (CGPoint)

+(NSValue*)valueWithCGPoint:(CGPoint)point
{
    return [NSValue valueWithPoint:NSPointFromCGPoint(point)];
}

-(CGPoint)CGPointValue
{
    return NSPointToCGPoint([self pointValue]);
}

+(NSValue *)valueWithCGRect:(CGRect)rect
{
    return [NSValue valueWithRect:NSRectFromCGRect(rect)];
}
- (CGRect)CGRectValue
{
    return NSRectToCGRect([self rectValue]);
}
@end

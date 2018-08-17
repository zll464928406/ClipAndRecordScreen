//
//  NSValue+CGPoint.h
//  Moxtra
//
//  Created by Raymond Xu on 11/8/13.
//  Copyright (c) 2013 Mxotra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSValue (CGPoint)

+(NSValue *)valueWithCGPoint:(CGPoint)point;
-(CGPoint)CGPointValue;

+(NSValue *)valueWithCGRect:(CGRect)rect;
- (CGRect)CGRectValue;

@end

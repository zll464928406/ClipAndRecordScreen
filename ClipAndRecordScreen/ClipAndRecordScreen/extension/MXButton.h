//
//  MXButton.h
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 6/27/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MXButton : NSButton

@property (nonatomic,readwrite, strong)NSColor *textColor;
@property (nonatomic,readwrite, assign)NSEdgeInsets texteEdgeInsets;
@property (nonatomic,readwrite, assign)NSEdgeInsets imageEdgeInsets;

@end

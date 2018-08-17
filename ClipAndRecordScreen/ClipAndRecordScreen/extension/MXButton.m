//
//  MXButton.m
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 6/27/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import "MXButton.h"
#import "MXButtonCell.h"

@implementation MXButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        MXButtonCell *cell = [[MXButtonCell alloc] init];
        [self setCell:cell];
    }
    return self;
}

- initWithCoder: (NSCoder *)origCoder
{
	BOOL sub = YES;
	
	sub = sub && [origCoder isKindOfClass: [NSKeyedUnarchiver class]]; // no support for 10.1 nibs
	sub = sub && ![self isMemberOfClass: [NSControl class]]; // no raw NSControls
	sub = sub && [[self superclass] cellClass] != nil; // need to have something to substitute
	sub = sub && [[self superclass] cellClass] != [[self class] cellClass]; // pointless if same
	
	if( !sub )
	{
		self = [super initWithCoder: origCoder];
	}
	else
	{
		NSKeyedUnarchiver *coder = (id)origCoder;
		
		// gather info about the superclass's cell and save the archiver's old mapping
		Class superCell = [[self superclass] cellClass];
		NSString *oldClassName = NSStringFromClass( superCell );
		Class oldClass = [coder classForClassName: oldClassName];
		if( !oldClass )
			oldClass = superCell;
		
		// override what comes out of the unarchiver
		[coder setClass: [[self class] cellClass] forClassName: oldClassName];
		
		// unarchive
		self = [super initWithCoder: coder];
		
		// set it back
		[coder setClass: oldClass forClassName: oldClassName];
	}
	
	return self;
}

+ (Class)cellClass
{
    return [MXButtonCell class];
}

- (void)setTextColor:(NSColor *)textColor
{
    _textColor = textColor;
    
    MXButtonCell *cell = self.cell;
    cell.textColor = textColor;
    
}

- (void)setTexteEdgeInsets:(NSEdgeInsets)texteEdgeInsets
{
    _texteEdgeInsets = texteEdgeInsets;
    
    MXButtonCell *cell = self.cell;
    cell.texteEdgeInsets = texteEdgeInsets;
}

- (void)setImageEdgeInsets:(NSEdgeInsets)imageEdgeInsets
{
    _imageEdgeInsets = imageEdgeInsets;
    MXButtonCell *cell = self.cell;
    cell.imageEdgeInsets = imageEdgeInsets;
}
@end

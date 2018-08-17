//
//  MXRecordToolbarViewController.m
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 6/27/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import "MXRecordToolbarViewController.h"

@implementation MXRecordToolbarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (NSString*)nibName
{
    return @"MXRecordToolbarViewController";
}

- (void)dealloc
{
    
}

- (void)awakeFromNib
{
    self.startNoteButton.title = NSLocalizedString(@"Start Record", @"Start Record");
    self.startNoteButton.textColor = [NSColor whiteColor];
    self.startNoteButton.texteEdgeInsets = NSEdgeInsetsMake(1,5,0,0);
}
- (IBAction)startNoteButtonClick:(id)sender {
    
    [self.delegate recordToolbarViewControllerStartNote:self];
    
}
@end

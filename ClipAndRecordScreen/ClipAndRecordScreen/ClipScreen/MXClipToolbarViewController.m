//
//  MXClipToolbarViewController.m
//  MoxtraDesktopAgent
//
//  Created by Raymond Xu on 6/27/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import "MXClipToolbarViewController.h"
#import "NSButton+TextColor.h"

@interface MXClipToolbarViewController ()

@end

@implementation MXClipToolbarViewController

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
    return @"MXClipToolbarViewController";
}

- (void)awakeFromNib
{
    self.clipButton.title = NSLocalizedString(@"OK", nil);
    self.cancelButton.title = NSLocalizedString(@"Cancel", nil);
    
    self.clipButton.textColor = [NSColor whiteColor];
    self.cancelButton.textColor = [NSColor whiteColor];
}

- (IBAction)cancelButtonClick:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(clipToolbarViewControllerCancel:)])
    {
        [self.delegate clipToolbarViewControllerCancel:self];
    }
}

- (IBAction)clipButtonClick:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(clipToolbarViewControllerCliped:)])
    {
        [self.delegate clipToolbarViewControllerCliped:self];
    }
}
@end

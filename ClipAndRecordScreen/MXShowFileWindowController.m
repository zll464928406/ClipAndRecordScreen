//
//  MXShowFileWindowController.m
//  ClipAndRecordScreen
//
//  Created by sunny on 2018/8/17.
//  Copyright © 2018 moxtra. All rights reserved.
//

#import "MXShowFileWindowController.h"

@interface MXShowFileWindowController ()

@end

@implementation MXShowFileWindowController

-(NSNibName)windowNibName
{
    return NSStringFromClass(self.class);
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

#pragma mark - User Action
- (IBAction)btnClicked:(id)sender
{
    [[NSWorkspace sharedWorkspace] selectFile:self.filePath inFileViewerRootedAtPath:@""];
}

@end

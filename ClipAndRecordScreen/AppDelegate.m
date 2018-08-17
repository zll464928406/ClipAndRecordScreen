//
//  AppDelegate.m
//  ClipAndRecordScreen
//
//  Created by sunny on 2018/8/17.
//  Copyright © 2018 moxtra. All rights reserved.
//

#import "AppDelegate.h"
#import "MXClipScreenManager.h"
#import "MXRecordScreenManager.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
}

#pragma mark - User Action
- (IBAction)clipScreenCLicked:(id)sender
{
    [[MXClipScreenManager sharedInstance] startCapture];
}

- (IBAction)recordScreenClicked:(id)sender
{
    [[MXRecordScreenManager sharedInstance] startRecordScreen];
}

@end

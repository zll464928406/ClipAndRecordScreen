//
//  MXAlertBlocks.m
//  Moxtra
//
//  Created by Raymond Xu on 12/18/13.
//  Copyright (c) 2013 Mxotra. All rights reserved.
//

#import "MXAlertBlocks.h"

@implementation MXAlertBlocks

+ (NSAlert*) showSheetModalForWindow:(NSWindow*) window
                             message:(NSString*) message
                     informativeText:(NSString*) text
                          alertStyle:(NSAlertStyle) style
                        buttonTitles:(NSArray*) otherButtons
                   completionHandler:(void (^)(NSModalResponse returnCode))handler
{
    
    MXAlertBlocks *alert = [[MXAlertBlocks alloc] init];
	[alert setMessageText:message];
	[alert setInformativeText:text];
	[alert setAlertStyle:style];
	
	for(NSString *buttonTitle in otherButtons)
		[alert addButtonWithTitle:buttonTitle];
    
    alert.handler = handler;
    
    [alert beginSheetModalForWindow:window modalDelegate:alert didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    
    return alert;
    
}

+ (NSAlert*) showModalMessage:(NSString*) message
              informativeText:(NSString*) text
                   alertStyle:(NSAlertStyle) style
                 buttonTitles:(NSArray*) otherButtons
            completionHandler:(void (^)(NSModalResponse returnCode))handler
{
    MXAlertBlocks *alert = [[MXAlertBlocks alloc] init];
	[alert setMessageText:message];
	[alert setInformativeText:text];
	[alert setAlertStyle:style];
	
	for(NSString *buttonTitle in otherButtons)
		[alert addButtonWithTitle:buttonTitle];
    
    alert.handler = handler;
    
    NSModalResponse returnCode = [alert runModal];
    
    if (alert.handler) {
        alert.handler(returnCode);
    }
    
    return alert;
}

+ (NSAlert*) showModleMessage:(NSString*) message title:(NSString*)title
{
    MXAlertBlocks *alert = [[MXAlertBlocks alloc] init];
	[alert setMessageText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Ok")];
    [alert runModal];
    
    return alert;
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (self.handler) {
        self.handler(returnCode);
    }
}

@end

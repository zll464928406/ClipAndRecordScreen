//
//  MXAlertBlocks.h
//  Moxtra
//
//  Created by Raymond Xu on 12/18/13.
//  Copyright (c) 2013 Mxotra. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^HandlerBlock)(NSModalResponse returnCode);

@interface MXAlertBlocks : NSAlert

@property (nonatomic, copy)HandlerBlock handler;

+ (NSAlert*) showSheetModalForWindow:(NSWindow*) window
                             message:(NSString*) message
                     informativeText:(NSString*) text
                          alertStyle:(NSAlertStyle) style
                   buttonTitles:(NSArray*) otherButtons
                   completionHandler:(void (^)(NSModalResponse returnCode))handler;

+ (NSAlert*) showModalMessage:(NSString*) message
                     informativeText:(NSString*) text
                          alertStyle:(NSAlertStyle) style
                        buttonTitles:(NSArray*) otherButtons
                   completionHandler:(void (^)(NSModalResponse returnCode))handler;

+ (NSAlert*) showModleMessage:(NSString*) message title:(NSString*)title;


@end

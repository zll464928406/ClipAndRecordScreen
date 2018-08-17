//
//  MXRecordScreenManager.m
//  MoxtraDesktopAgent
//
//  Created by sunny on 2018/7/9.
//  Copyright © 2018年 moxtra. All rights reserved.
//

#import "MXRecordScreenManager.h"
#import "MXRecordScreenWindowController.h"
#import <AVFoundation/AVFoundation.h>
#import "MXShowFileWindowController.h"

@interface MXRecordScreenManager () <MXRecordScreenWindowControllerDelegate>

@property (nonatomic, strong) NSMutableArray<MXRecordScreenWindowController*> *recordWindowControllerArray;

@property (nonatomic, strong) MXShowFileWindowController *showFileWindowController;

@end

@implementation MXRecordScreenManager

+ (instancetype)sharedInstance
{
    static MXRecordScreenManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void) {
        sharedInstance = [[MXRecordScreenManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.recordWindowControllerArray = [NSMutableArray array];
        self.isWorking = NO;
    }
    return self;
}

#pragma mark - Public Methods
- (void)startRecordScreen
{
    NSOperatingSystemVersion systemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    NSInteger majorVersion = systemVersion.majorVersion;
    NSInteger minorVersion = systemVersion.minorVersion;
    if ((majorVersion == 10 && minorVersion >= 14)
        || majorVersion > 10)
    {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (authStatus != AVAuthorizationStatusAuthorized)
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (granted)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self readyToRecordScreen];
                    });
                }
            }];
        }
        else
        {
            [self readyToRecordScreen];
        }
    }
    else
    {
        [self readyToRecordScreen];
    }
}

- (void)readyToRecordScreen
{
    if (self.isWorking) return;
    self.isWorking = YES;
    
    [self clearRecordWindowControllerArray];
    self.arrayRect = [NSMutableArray array];
    NSArray *windowArray = (__bridge NSArray *) CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    for (NSUInteger i = 0; i < windowArray.count; i++)
    {
        NSDictionary *windowDescriptionDictionary = windowArray[i];
        [self.arrayRect addObject:windowDescriptionDictionary];
    }
    
    for (NSScreen *screen in [NSScreen screens])
    {
        MXRecordScreenWindowController *recordWindowController = [[MXRecordScreenWindowController alloc] initWithDelegate:self];
        [recordWindowController startRecorderScreen:screen];
        
        [self.recordWindowControllerArray addObject:recordWindowController];
    }
}

- (void)changeKeyWindowWithScreen:(NSScreen*)screen
{
    for (MXRecordScreenWindowController *windowController in self.recordWindowControllerArray)
    {
        if ([windowController.screen isEqual:screen])
        {
            [windowController.window makeKeyAndOrderFront:nil];
        }
    }
}

- (void)reset
{
    self.isWorking = NO;
    [self clearRecordWindowControllerArray];
}

#pragma mark - MXRecordScreenWindowControllerDelegate
- (void)recordScreenWindowController:(MXRecordScreenWindowController*)controller finishRecordWithFileName:(NSString *)fileName saveToLocal:(BOOL)saveTolocal
{
    [self clearRecordWindowControllerArray];
    self.isWorking = NO;
    
    // show video window
    self.showFileWindowController = [[MXShowFileWindowController alloc] init];
    self.showFileWindowController.filePath = fileName;
    [self.showFileWindowController showWindow:nil];
    [self.showFileWindowController.window center];
}

- (void)recordScreenWindowControllerDidSelectRegion:(MXRecordScreenWindowController*)windowController
{
    [self.recordWindowControllerArray enumerateObjectsUsingBlock:^(MXRecordScreenWindowController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isEqual:windowController])
        {
            [obj.window orderOut:nil];
        }
    }];
}

- (void)recordScreenWindowControllerRemoveEventMonitor:(MXRecordScreenWindowController*)windowController
{
    [self.recordWindowControllerArray enumerateObjectsUsingBlock:^(MXRecordScreenWindowController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeEventMonitor];
    }];
}

- (void)recordScreenWindowControllerDidCancel:(MXRecordScreenWindowController*)windowController
{
    [self clearRecordWindowControllerArray];
    self.isWorking = NO;
}

#pragma mark - Private Methods
- (void)clearRecordWindowControllerArray
{
    if (self.recordWindowControllerArray.count > 0)
    {
        [self.recordWindowControllerArray enumerateObjectsUsingBlock:^(MXRecordScreenWindowController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.delegate = nil;
            [obj cleanup];
        }];
        
        [self.recordWindowControllerArray removeAllObjects];
    }
}

@end

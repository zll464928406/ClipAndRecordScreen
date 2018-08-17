//
//  MXClipScreenManager.m
//  MoxtraDesktopAgent
//
//  Created by sunny on 2018/7/6.
//  Copyright © 2018年 moxtra. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "MXClipScreenManager.h"
#import "MXClipWindowController.h"
#import "MXClipView.h"

@interface MXClipScreenManager () <MXClipWindowControllerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSMutableArray<MXClipWindowController*> *clipWindowControllerArray;

@end

@implementation MXClipScreenManager

+ (instancetype)sharedInstance
{
    static MXClipScreenManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void) {
        sharedInstance = [[MXClipScreenManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.clipWindowControllerArray = [NSMutableArray array];
        self.isWorking = NO;
        NSString *musicFilePath = [[NSBundle mainBundle] pathForResource:@"1356" ofType:@"wav"];
        if (musicFilePath.length)
        {
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:musicFilePath] error:nil];
            [self.audioPlayer prepareToPlay];
        }
    }
    return self;
}

#pragma mark - Public Methods
- (void)startCapture
{
    if (self.isWorking) return;
    self.isWorking = YES;
    
    [self clearClipWindowControllerArray];
    self.arrayRect = [NSMutableArray array];
    NSArray *windowArray = (__bridge NSArray *) CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    for (NSUInteger i = 0; i < windowArray.count; i++)
    {
        NSDictionary *windowDescriptionDictionary = windowArray[i];
        [self.arrayRect addObject:windowDescriptionDictionary];
    }
    
    for (NSScreen *screen in [NSScreen screens])
    {
        MXClipWindowController *clipWindowController = [[MXClipWindowController alloc] initWithDelegate:self];
        [clipWindowController startCaptureWithScreen:screen];
        
        [self.clipWindowControllerArray addObject:clipWindowController];
    }
}

- (void)changeKeyWindowWithScreen:(NSScreen*)screen
{
    for (MXClipWindowController *windowController in self.clipWindowControllerArray)
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
    [self clearClipWindowControllerArray];
}

- (void)clearClipWindowControllerArray
{
    if (self.clipWindowControllerArray.count > 0)
    {
        [self.clipWindowControllerArray enumerateObjectsUsingBlock:^(MXClipWindowController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.delegate = nil;
            if ([obj.window isVisible])
            {
                [obj.window orderOut:nil];
            }
        }];
        [self.clipWindowControllerArray removeAllObjects];
    }
}

#pragma mark - MXClipWindowControllerDelegate
- (void)clipWindowController:(MXClipWindowController*)windowController didClipedWithImage:(NSImage*)image
{
    [self.audioPlayer play];
    
    [self.clipWindowControllerArray enumerateObjectsUsingBlock:^(MXClipWindowController * _Nonnull winCtr, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![winCtr isEqual:windowController])
        {
            [winCtr endCapture];
        }
    }];
    
    [self clearClipWindowControllerArray];
    self.isWorking = NO;
    
    // show image window
}

- (void)clipWindowControllerDidCancel:(MXClipWindowController*)windowController
{
    [self.clipWindowControllerArray enumerateObjectsUsingBlock:^(MXClipWindowController * _Nonnull winCtr, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![winCtr isEqual:windowController])
        {
            [winCtr endCapture];
        }
    }];
    
    [self clearClipWindowControllerArray];
    self.isWorking = NO;
}

@end

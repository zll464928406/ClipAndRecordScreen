//
//  MXCaptureScreenSession.h
//  AVAssetWriterDemo
//
//  Created by Raymond Xu on 8/22/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AppKit/AppKit.h>

enum {
    CSStatusNone,
    CSStatusStop,
    CSStatusRecording,
    CSStatusPaused,
};
typedef NSUInteger CSStatus;

enum {
    CSErrorNone,
    CSErrorMaximumFileSizeReached,
};
typedef NSUInteger CSErrorCode;

@class MXCaptureScreenSession;

@protocol MXCaptureScreenSessionDelegate <NSObject>

- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didReadyToRecordingToPath:(NSString*)path;
- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didStartRecordingToPath:(NSString*)path;
- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didPauseRecordingToPath:(NSString*)path;
- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didResumeRecordingToPath:(NSString*)path;
- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession didFinishRecordingToPath:(NSString*)path error:(CSErrorCode)error;
- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession runtimeErrorDidOccur:(NSError*)error;
- (void)captureScreenSession:(MXCaptureScreenSession*)captureSession startWriteError:(NSError*)error;

@end

@interface MXCaptureScreenSession : NSObject

@property (nonatomic, assign) id<MXCaptureScreenSessionDelegate> delegate;
@property (nonatomic, assign) CMTime recordedDuration;
@property (nonatomic, assign) NSUInteger maximumFileSize;
@property (nonatomic, assign) float frameRate;
@property (nonatomic, assign) CSStatus status;
@property (nonatomic, strong) NSArray *exceptWinodwArray;
@property (nonatomic, assign, readonly) float audioPowerLevels;

- (void)recordToPath:(NSString*)path withCropRect:(NSRect)rect forScreen:(NSScreen*)screen;
- (void)startRecording;
- (void)stopRecording;
- (void)pauseRecording;
- (void)resumeRecording;
- (Float64)countRecordedDuration;

@end

//
//  MXCaptureScreenSession.m
//  AVAssetWriterDemo
//
//  Created by Raymond Xu on 8/22/14.
//  Copyright (c) 2014 moxtra. All rights reserved.
//

#import <ApplicationServices/ApplicationServices.h>
#import "MXCaptureScreenSession.h"
//#import "MXConfigureManager.h"

#define CAPTURE_FRAME_RATE    4

@interface MXCaptureScreenSession ()<AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) dispatch_queue_t movieWritingQueue;
@property (nonatomic, assign) CSErrorCode errorCode;
@property (nonatomic, assign) BOOL pause;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL checkFile;

@property (nonatomic, assign) NSRect captureRect;
@property (nonatomic, strong) NSScreen *captureScreen;

@property (nonatomic, strong) AVCaptureSession            *audioCaptureSession;
@property (nonatomic, strong) AVAssetWriter               *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput          *audioAssetWriterInput;

@property (nonatomic, strong) dispatch_source_t                     videoOutputTimer;
@property (nonatomic, strong) dispatch_queue_t                      videoOutputQueue;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor  *adaptor;
@property (nonatomic, assign) BOOL                                  videoStoped;
@property (nonatomic, assign) BOOL                                  videoPaused;

@property (nonatomic, strong) AVCaptureDeviceInput        *audioCaptureAudioDeviceInput;
@property (nonatomic, strong) AVCaptureAudioDataOutput    *audioCaptureAudioDataOutput;
@property (nonatomic, strong) dispatch_queue_t             audioDataOutputQueue;
@property (nonatomic, assign) CMTime                       audioStartSampleTime;
@property (nonatomic, assign) BOOL                         readyToRecordAudio;
@property (nonatomic, assign) BOOL                         audioStoped;
@property (nonatomic, assign) BOOL                         audioPaused;

@end

@implementation MXCaptureScreenSession

- (void)dealloc
{
    if (self.status == CSStatusPaused || self.status == CSStatusRecording) {
        [self stopRecording];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods
- (void)recordToPath:(NSString*)path withCropRect:(NSRect)cropRect forScreen:(NSScreen*)screen
{
    if (NSIsEmptyRect(cropRect) || (!screen) || self.status == CSStatusRecording) {
        return;
    }
    
    self.captureRect = cropRect;
    self.captureScreen = screen;
    self.filePath = path;
    
    self.audioStoped = NO;
    self.videoStoped = NO;
    self.audioPaused = NO;
    self.videoPaused  = NO;
    self.readyToRecordAudio = NO;
    self.pause = NO;
    self.errorCode = CSErrorNone;
    self.checkFile = YES;
    
    NSError *error = nil;
    
    //----initialize compression engine
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(self.assetWriter);
    if(error)
    {
        [self.delegate captureScreenSession:self runtimeErrorDidOccur:error];
    }
    
    self.movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
    
    [self startCaptureAuido];
    [self startCaptureVideo];
    
    self.status = CSStatusRecording;
}

- (void)startRecording
{
    @synchronized(self) {
        self.started = YES;
    }
}

- (void)stopRecording
{
    if (self.status != CSStatusRecording && self.status != CSStatusPaused) {
        return;
    }
    
    [self.audioCaptureSession stopRunning];
    
    if (self.videoOutputTimer) {
        if (self.status == CSStatusPaused) {
            dispatch_resume(self.videoOutputTimer);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_source_cancel(self.videoOutputTimer);
        });
    }
    
    self.status = CSStatusStop;
    @synchronized(self) {
        self.started = NO;
    }
}

- (void)pauseRecording
{
    if (self.status != CSStatusRecording) {
        return;
    }
    
    dispatch_suspend(self.videoOutputTimer);
    self.videoPaused = YES;
    dispatch_async(self.movieWritingQueue, ^{
        if (self.audioPaused)
        {
            self.status = CSStatusPaused;
            [self.delegate captureScreenSession:self didPauseRecordingToPath:self.filePath];
        }
    });
    
    self.pause = YES;
}

- (void)resumeRecording
{
    if (self.status != CSStatusPaused) {
        return;
    }
    
    dispatch_resume(self.videoOutputTimer);
    
    self.pause = NO;
    
    dispatch_async(self.movieWritingQueue, ^{
        
        [self.delegate captureScreenSession:self didResumeRecordingToPath:self.filePath];
        self.status = CSStatusRecording;
    });
}

- (Float64)countRecordedDuration
{
    __block Float64 recordedDuration = 0;
    if (self.videoOutputQueue) {
        dispatch_sync(self.videoOutputQueue, ^{
            recordedDuration = CMTimeGetSeconds(self.recordedDuration);
        });
    }
    return recordedDuration;
}

#pragma mark- Private Methods
- (void)startCaptureVideo
{
    CGSize size = self.captureRect.size;
    
#if 1 //H264
    
    float bitsPerPixel = 2;
    double bitPerSecond = size.width*size.height*bitsPerPixel;
    
    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithDouble:bitPerSecond], AVVideoAverageBitRateKey,
                                   [NSNumber numberWithInt:self.frameRate >0? self.frameRate:CAPTURE_FRAME_RATE],AVVideoMaxKeyFrameIntervalKey,
                                   nil];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   codecSettings,AVVideoCompressionPropertiesKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
#else //JPEG
    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithDouble:0.3], AVVideoQualityKey,
                                   nil];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   codecSettings,AVVideoCompressionPropertiesKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
#endif
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    writerInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    if (![self.assetWriter canAddInput:writerInput]) {
        
        NSError *error = self.assetWriter.error;
        [self.delegate captureScreenSession:self runtimeErrorDidOccur:error];
        return;
    }
    
    [self.assetWriter addInput:writerInput];
    
    self.videoOutputQueue = dispatch_queue_create("VideoOutputQueue",NULL);
    self.videoOutputTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.videoOutputQueue);
    
    int __block imageRefCount = 0;
    
    dispatch_source_set_event_handler(self.videoOutputTimer, ^{
        
        self.recordedDuration = CMTimeMake(imageRefCount, CAPTURE_FRAME_RATE);
        // get captured image for this time
        CGImageRef outImageRef = [self getCapturedImage];
        if (self.status == CSStatusStop)
        {
            outImageRef = [self getWaterMarkerImageRef];
        }
        
        if ([writerInput isReadyForMoreMediaData])
        {
            dispatch_async(self.movieWritingQueue, ^{
                if ([self addImageRefToMovie:outImageRef size:size frame:imageRefCount])
                {
                    ++imageRefCount;
                }
            });
        }
        else
        {
            dispatch_async(self.movieWritingQueue, ^{
                if ([writerInput isReadyForMoreMediaData] )
                {
                    ++imageRefCount;
                }
            });
        }
    });
    
    dispatch_source_set_cancel_handler(self.videoOutputTimer, ^{
        
        // water marker for end of video
        CGImageRef waterMakerImageRef = [self getWaterMarkerImageRef];
        
        dispatch_async(self.movieWritingQueue, ^{
            
            if ([writerInput isReadyForMoreMediaData])
            {
                if ([self addImageRefToMovie:waterMakerImageRef size:size frame:imageRefCount])
                {
                    ++imageRefCount;
                }
            }
        });
        
        self.videoOutputTimer = nil;
        self.videoOutputQueue = nil;
        self.captureRect = NSZeroRect;
        self.videoPaused = NO;
        
        dispatch_async(self.movieWritingQueue, ^{
            
            if (self.assetWriter.status == AVAssetWriterStatusWriting)
            {
                [writerInput markAsFinished];
            }
            
            self.videoStoped = YES;
            if (self.audioStoped)
            {
                [self.assetWriter finishWriting];
                self.assetWriter = nil;
                
                [self.delegate captureScreenSession:self didFinishRecordingToPath:self.filePath error:self.errorCode];
                //self.movieWritingQueue = nil;
            }
        });
    });
    
    dispatch_source_set_timer(self.videoOutputTimer, dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/CAPTURE_FRAME_RATE) , NSEC_PER_SEC/CAPTURE_FRAME_RATE, 0);
    
    dispatch_resume(self.videoOutputTimer);
}

- (void)startCaptureAuido
{
    NSError *error = nil;
    
    //audio
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    self.audioCaptureSession = [[AVCaptureSession alloc] init];
    if (!self.audioCaptureSession)
    {
        return;
    }
    
    self.audioCaptureAudioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!self.audioCaptureAudioDeviceInput){
        NSLog(@"get deview input with device failed");
        return;
    }
    
    if ([self.audioCaptureSession canAddInput: self.audioCaptureAudioDeviceInput]) {
        [self.audioCaptureSession addInput:self.audioCaptureAudioDeviceInput];
    } else {
        NSLog(@"add audio input to session failed");
        return;
    }
    
    // Create and add a AVCaptureAudioDataOutput object to the session
    self.audioCaptureAudioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    if (!self.audioCaptureAudioDataOutput) {
        return;
    }
    
    if ([self.audioCaptureSession canAddOutput:self.audioCaptureAudioDataOutput]) {
        [self.audioCaptureSession addOutput:self.audioCaptureAudioDataOutput];
    } else {
        NSLog(@"add audio data output to session failed");
        return;
    }
    
    dispatch_queue_t audioDataOutputQueue = dispatch_queue_create("AudioDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    if (!audioDataOutputQueue){
        return;
    }
    
    [self.audioCaptureAudioDataOutput setSampleBufferDelegate:self queue:audioDataOutputQueue];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionStoppedRunningNotification:) name:AVCaptureSessionDidStopRunningNotification object:self.audioCaptureSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionRuntimeErrorNotification:) name:AVCaptureSessionRuntimeErrorNotification object:self.audioCaptureSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionDidStartRunningNotification:) name:AVCaptureSessionDidStartRunningNotification object:self.audioCaptureSession];
    
    [self.audioCaptureSession startRunning];
}

- (CGImageRef)getCapturedImage
{
    float screenHeight = [[[NSScreen screens] firstObject] frame].size.height;
    float y = screenHeight - self.captureRect.size.height - self.captureRect.origin.y;
    
    CGRect clipRect = CGRectMake(NSMinX(self.captureRect), y, NSWidth(self.captureRect), NSHeight(self.captureRect));
    
    CGImageRef imageRef = nil;
    if (self.exceptWinodwArray.count>0)
    {
        CFArrayRef onScreenWindows = CGWindowListCreate(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
        CFMutableArrayRef desktopElements = CFArrayCreateMutableCopy(NULL, 0, onScreenWindows);
        for (long i = CFArrayGetCount(desktopElements) - 1; i >= 0; i--)
        {
            CGWindowID windowId = (CGWindowID)(uintptr_t)CFArrayGetValueAtIndex(desktopElements, i);
            NSArray *windowDic = (__bridge_transfer NSArray*)CGWindowListCopyWindowInfo(kCGWindowListOptionIncludingWindow, windowId);
            for (NSDictionary *Window in windowDic)
            {
                [self.exceptWinodwArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSNumber *objExceptWinodId = obj;
                    if ([objExceptWinodId isKindOfClass:[NSNumber class]])
                    {
                        CGWindowID exceptWinodw = [objExceptWinodId unsignedIntValue];
                        
                        if (windowId == exceptWinodw)
                        {
                            CFArrayRemoveValueAtIndex(desktopElements, i);
                        }
                    }
                }];
            }
        }
        
        imageRef = CGWindowListCreateImageFromArray(clipRect, desktopElements, kCGWindowListOptionAll|kCGWindowImageNominalResolution);
        CFRelease(desktopElements);
        CFRelease(onScreenWindows);
    }
    else
    {
        imageRef = CGWindowListCreateImage(clipRect,
                                           kCGWindowListOptionOnScreenOnly,
                                           kCGNullWindowID,
                                           kCGWindowImageDefault
                                           );
    }
    
    CGImageRef outImageRef = [self appendMouseCursor:imageRef];
    CGImageRelease(imageRef);
    
    return outImageRef;
}

- (CGImageRef)getWaterMarkerImageRef
{
    NSImage *image = [self getMoxtraLogoImageForRecording];
    NSData * imageData = [image TIFFRepresentation];
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    CFRelease(imageSource);
    return imageRef;
}

- (BOOL)addImageRefToMovie:(CGImageRef)imageRef size:(CGSize)size frame:(int)frame
{
    if (self.errorCode == CSErrorMaximumFileSizeReached)
    {
        return NO;
    }
    
    CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:imageRef size:size];
    if (buffer)
    {
        if(![self.adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeAdd (CMTimeMake(frame, CAPTURE_FRAME_RATE), self.audioStartSampleTime)])
        {
            NSError *error = self.assetWriter.error;
            [self.delegate captureScreenSession:self runtimeErrorDidOccur:error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self stopRecording];
            });
        }
        
        CVPixelBufferRelease(buffer);
    }
    
    CGImageRelease(imageRef);
    
    if (self.checkFile)
    {
        [self checkFileSize];
    }
    return YES;
}

- (float)audioPowerLevels
{
    if (self.status !=CSStatusRecording ) {
        return 0.0f;
    }
    NSInteger channelCount = 0;
    float prowserlevels = 0.f;
    //NSArray *allChannels = self.audioCaptureAudioDataOutput.connections;
    
    for (AVCaptureConnection *connection in self.audioCaptureAudioDataOutput.connections) {
        
        for (AVCaptureAudioChannel *audioChannel in connection.audioChannels) {
            prowserlevels += [audioChannel averagePowerLevel];
            channelCount += 1;
        }
    }
    
    prowserlevels /= channelCount;
    
    prowserlevels = (pow(10.f, 0.05f * prowserlevels) * 20.0f);
    
    return prowserlevels;
}

- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)formatDescription
{
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
    
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, &aclSize);
    NSData *currentChannelLayoutData = nil;
    
    // AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
    if ( currentChannelLayout && aclSize > 0 )
        currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
    else
        currentChannelLayoutData = [NSData data];
    
    NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                              [NSNumber numberWithFloat:8000], AVSampleRateKey,
                                              //[NSNumber numberWithInt:64000], AVEncoderBitRatePerChannelKey,
                                              [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
                                              currentChannelLayoutData, AVChannelLayoutKey,
                                              nil];
    
    if ([self.assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
        self.audioAssetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
        self.audioAssetWriterInput.expectsMediaDataInRealTime = YES;
        if ([self.assetWriter canAddInput:self.audioAssetWriterInput])
            [self.assetWriter addInput:self.audioAssetWriterInput];
        else {
            
            NSLog(@"Couldn't add asset writer audio input.");
            return NO;
        }
    }
    else {
        NSLog(@"Couldn't apply audio output settings.");
        return NO;
    }
    
    return YES;
}

- (void)checkFileSize
{
    if (self.maximumFileSize > 0)
    {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:nil];
        long long fileSize = [[attributes objectForKey:NSFileSize] longLongValue];
        
        if (fileSize >= self.maximumFileSize * 0.92)
        {
            self.errorCode = CSErrorMaximumFileSizeReached;
            self.checkFile = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopRecording];
            });
        }
    }
}

- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, (kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst));
    NSParameterAssert(context);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

-(CGImageRef)appendMouseCursor:(CGImageRef)pSourceImage{
    // get the cursor image
    NSPoint mouseLoc;
    mouseLoc = [NSEvent mouseLocation]; //get cur
    
    // get the mouse image
    NSImage *overlay    =   [[NSCursor arrowCursor] image];
    
    int x = (int)mouseLoc.x;
    int y = (int)mouseLoc.y;
    int w = (int)[overlay size].width;
    int h = (int)[overlay size].height;
    
    NSPoint offset = [[NSCursor arrowCursor] hotSpot];
    
    int org_x = x - self.captureRect.origin.x - offset.x;
    
    int org_y = y- self.captureRect.origin.y - (h/2 + offset.y);
    
    size_t height = self.captureRect.size.height;
    size_t width =  self.captureRect.size.width;
    size_t bytesPerRow = CGImageGetBytesPerRow(pSourceImage);
    
    unsigned int * imgData = (unsigned int*)malloc(height*bytesPerRow);
    
    // have the graphics context now,
    CGRect bgBoundingBox = CGRectMake (0, 0, width,height);
    
    CGContextRef context =  CGBitmapContextCreate(imgData, width,
                                                  height,
                                                  8, // 8 bits per component
                                                  bytesPerRow,
                                                  CGImageGetColorSpace(pSourceImage),
                                                  CGImageGetBitmapInfo(pSourceImage));
    
    // first draw the image
    CGContextDrawImage(context,bgBoundingBox,pSourceImage);
    
    // then mouse cursor
    CGContextDrawImage(context,CGRectMake(org_x, org_y, w,h),[overlay CGImageForProposedRect: NULL context: NULL hints: NULL] );
    
    
    // assuming both the image has been drawn then create an Image Ref for that
    
    CGImageRef pFinalImage = CGBitmapContextCreateImage(context);
    
    free(imgData);
    CGContextRelease(context);
    
    return pFinalImage; /* to be released by the caller */
}

- (NSImage *)getMoxtraLogoImageForRecording
{
    CGSize imgsize = NSSizeToCGSize(self.captureRect.size);
    
    NSImage *logoimage = nil;
    NSString *waterMarkPath = [[NSBundle mainBundle] pathForResource:@"preferencesRemoteAgent" ofType:@"png"];
    if (waterMarkPath.length>0) {
        logoimage = [[NSImage alloc] initWithContentsOfFile:waterMarkPath];
    }
    else
        logoimage = [NSImage imageNamed:@"preferencesRemoteAgent"];
    
    CGSize maximgsize = CGSizeMake((imgsize.width*4)/5, (imgsize.height*4)/5);
    
    NSRect drawrect = scaleSizeCentralRect(logoimage.size, NSMakeRect((imgsize.width-maximgsize.width)/2, (imgsize.height-maximgsize.height)/2, maximgsize.width, maximgsize.height));
    
    NSRect backgroundRect = NSMakeRect(0, 0, imgsize.width, imgsize.height);
    
    NSImage *jpegImage = [[NSImage alloc] initWithSize:NSMakeSize(imgsize.width, imgsize.height)];
    [jpegImage lockFocus];
    
    
    CGFloat f = 33.0/255.0;
    [[NSColor colorWithDeviceRed:f green:f blue:f alpha:0.75] set];
    NSRectFill(backgroundRect);
    
    NSSize imageSize = logoimage.size;
    
    NSAffineTransform *trans = [[NSAffineTransform alloc] init];
    [trans set];
    
    [logoimage drawInRect:drawrect fromRect:NSMakeRect(0,0,imageSize.width,imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    [jpegImage unlockFocus];
    
    return jpegImage;
}

NSRect scaleSizeCentralRect(NSSize orgsize, NSRect maxrect)
{
    if (orgsize.width<1.0 || orgsize.height<1.0 ||
        maxrect.size.width<1.0 || maxrect.size.height<1.0)
    {
        return NSMakeRect(maxrect.origin.x, maxrect.origin.y, 0, 0);
    }
    
    CGFloat scalex = orgsize.width/maxrect.size.width;
    CGFloat scaley = orgsize.height/maxrect.size.height;
    CGFloat scale = MAX(scalex, scaley);
    
    CGFloat width = orgsize.width / scale;
    CGFloat height = orgsize.height / scale;
    
    return NSMakeRect(maxrect.origin.x + (maxrect.size.width-width)/2.0, maxrect.origin.y + (maxrect.size.height-height)/2.0, width, height);
}

#pragma mark- AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (captureOutput == self.audioCaptureAudioDataOutput) {
        
        if (self.assetWriter) {
            
            if (!self.readyToRecordAudio) {
                
                CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                self.readyToRecordAudio = [self setupAssetWriterAudioInput:formatDescription];
            }
            
            if (self.assetWriter.status == AVAssetWriterStatusUnknown ) {
                
                if (self.started ) {
                    
                    if ([self.assetWriter startWriting]) {
                        self.audioStartSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                        [self.assetWriter startSessionAtSourceTime:self.audioStartSampleTime];
                        
                        [self.delegate captureScreenSession:self didStartRecordingToPath:self.filePath];
                    }
                    else {
                        [self.delegate captureScreenSession:self startWriteError:self.assetWriter.error];
                    }
                    
                }
            }
            else if ( self.assetWriter.status == AVAssetWriterStatusWriting ) {
                
                if (self.pause) {
                    
                    self.audioPaused = YES;
                    
                    if (self.status != CSStatusPaused) {
                        
                        dispatch_async(self.movieWritingQueue, ^{
                            if (self.videoPaused) {
                                self.status = CSStatusPaused;
                                [self.delegate captureScreenSession:self didPauseRecordingToPath:self.filePath];
                                
                            }
                        });
                    }
                    
                }
                else {
                    
                    CFRetain(sampleBuffer);
                    dispatch_async(self.movieWritingQueue, ^{
                        
                        if (self.audioAssetWriterInput.readyForMoreMediaData) {
                            
                            if (self.errorCode == CSErrorMaximumFileSizeReached) {
                                return;
                            }
                            
                            [self.audioAssetWriterInput appendSampleBuffer:sampleBuffer];
                        }
                        
                        CFRelease(sampleBuffer);
                        
                        if (self.checkFile) {
                            [self checkFileSize];
                        }
                        
                    });
                }
                
                
            }
        }
        else {
            
        }
    }
}

- (void)captureSessionStoppedRunningNotification:(NSNotification *)notification
{
    [self.audioCaptureSession removeInput:self.audioCaptureAudioDeviceInput];
    [self.audioCaptureSession removeOutput:self.audioCaptureAudioDataOutput];
    
    self.audioAssetWriterInput = nil;
    self.audioCaptureAudioDeviceInput = nil;
    self.audioCaptureAudioDataOutput = nil;
    self.audioCaptureSession = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	dispatch_async(self.movieWritingQueue, ^{
		
        if (self.assetWriter.status == AVAssetWriterStatusWriting) {
            [self.audioAssetWriterInput markAsFinished];
        }
        
        self.audioStoped = YES;
        
        if (self.videoStoped) {
            [self.assetWriter finishWriting];
            self.assetWriter = nil;
            
           [self.delegate captureScreenSession:self didFinishRecordingToPath:self.filePath error:self.errorCode];
            
            //self.movieWritingQueue = nil;
        }
	});
}

- (void)captureSessionRuntimeErrorNotification:(NSNotification *)notification
{
    NSError *error = [notification userInfo][AVCaptureSessionErrorKey];
    
    [self.delegate captureScreenSession:self runtimeErrorDidOccur:error];
}

- (void)captureSessionDidStartRunningNotification:(NSNotification *)notification
{
    [self.delegate captureScreenSession:self didReadyToRecordingToPath:self.filePath];
}

@end

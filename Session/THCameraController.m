//
//  THCameraController.m
//  Session
//
//  Created by lvzhenhua on 2017/11/18.
//  Copyright © 2017年 lvzhenhua. All rights reserved.
//

#import "THCameraController.h"
#import <AssetsLibrary/AssetsLibrary.h>
@interface THCameraController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic ,strong) dispatch_queue_t videoQueue;

@property (nonatomic ,strong) AVCaptureSession *captureSession;
@property (strong ,nonatomic) AVCaptureDeviceInput *activeVideoInput;
@property (nonatomic ,strong) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic ,strong) AVCaptureMovieFileOutput *movieOutput;
@property (nonatomic ,strong) NSURL *outputURL;
@end

@implementation THCameraController

static const NSString *THCameraAdjustingExposureContext;

- (BOOL)setupSession:(NSError *)error {
    //1.create an session
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    //2.get a reference to default camera
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *errors ;
    //3.create a device input for the camera
    AVCaptureDeviceInput *cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&errors];
    self.activeVideoInput = cameraInput;
    //[self.captureSession beginConfiguration];
    if (cameraInput) {
        if ([self.captureSession canAddInput:cameraInput]) {
            [self.captureSession addInput:cameraInput];
        }
    }else return NO;
    //4.setup Mircophone
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    if (audioInput) {
        if ([self.captureSession canAddInput:audioInput]) {
            [self.captureSession addInput:audioInput];
        }
    }else return NO;
    
    //5.output
    //setup image output
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    self.imageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    if ([self.captureSession canAddOutput:self.imageOutput]) {
        [self.captureSession addOutput:self.imageOutput];
    }
    //setup movie file output
    self.movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.captureSession canAddOutput:self.movieOutput]) {
        [self.captureSession addOutput:self.movieOutput];
    }
    self.videoQueue = dispatch_queue_create("com.tapharmonic.VideoQueue", NULL);
    //[self.captureSession commitConfiguration];
    return YES;
}

- (void)startSession {
    if (![self.captureSession isRunning]) {
        dispatch_async(self.videoQueue, ^{
            [self.captureSession startRunning];
        });
    }
}

- (void)stopSession {
    if ([self.captureSession isRunning]) {
        dispatch_async(self.videoQueue, ^{
            [self.captureSession stopRunning];
        });
    }
}

- (BOOL)canSwitchCameras {
    return self.cameraCount > 1;
}

- (BOOL)switchCameras {
    if (![self canSwitchCameras]) {
        return NO;
    }
    NSError *error;
    AVCaptureDevice *videoCamera = [self inactiveDevice];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCamera error:&error];
    if (videoInput) {
            [self.captureSession beginConfiguration];
            [self.captureSession removeInput:self.activeVideoInput];
        if ([self.captureSession canAddInput:videoInput]) {
            [self.captureSession addInput:videoInput];
            self.activeVideoInput = videoInput;
        } else {
            [self.captureSession addInput:self.activeVideoInput];
        }
        [self.captureSession commitConfiguration];
    } else {
        [self.delegate deviceConfigurationFailedWithError:error];
    }
    return YES;
}
- (NSUInteger)cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (BOOL)cameraSupportsTapToFocus {
    return [[self activeDevice] isFocusPointOfInterestSupported];
}

- (void)focusAtPoint:(CGPoint)point {
    AVCaptureDevice *device = [self activeDevice];
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        } else {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}

- (BOOL)cameraSupportsTapToExpose  {
    return [[self activeDevice] isExposurePointOfInterestSupported];
}

- (void)exposeAtPoint:(CGPoint)point {
    AVCaptureDevice *device = [self activeDevice];
    
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeAutoExpose;
    if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.exposurePointOfInterest = point;
            device.exposureMode = exposureMode;
            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
                [device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:&THCameraAdjustingExposureContext];
            }
            [device unlockForConfiguration];
        } else {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == &THCameraAdjustingExposureContext) {
        AVCaptureDevice *device = (AVCaptureDevice *)object;
        if (!device.isAdjustingExposure && [device isExposureModeSupported:AVCaptureExposureModeLocked]) {
            [object removeObserver:self forKeyPath:@"adjustingExposure" context:&THCameraAdjustingExposureContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                if ([device lockForConfiguration:&error]) {
                    device.exposureMode = AVCaptureExposureModeLocked;
                    [device unlockForConfiguration];
                } else {
                    [self.delegate deviceConfigurationFailedWithError:error];
                }
            });
        }
    }  else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)resetFocusAndExposeModes {
    AVCaptureDevice *device = [self activeDevice];
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    BOOL canResetFocus = [device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode];
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    BOOL canResetExposure = [device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode];
    CGPoint centerPoint =CGPointMake(0.5f, 0.5f);
    
    NSError *error;
    if ([device lockForConfiguration:&error]) {
        if (canResetFocus) {
            device.focusMode = focusMode;
            device.focusPointOfInterest = centerPoint;
        }
        
        if (canResetExposure) {
            device.exposureMode = exposureMode;
            device.exposurePointOfInterest = centerPoint;
        }
        [device unlockForConfiguration];
    } else {
        [self.delegate deviceConfigurationFailedWithError:error];
    }
}

#pragma mark - 闪关灯和聚焦
- (BOOL)canemraHasFalsh {
    return [[self activeDevice] hasFlash];
}

- (AVCaptureFlashMode)flashMode {
    return [[self activeDevice] flashMode];
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    AVCaptureDevice *device = [self activeDevice];
    if ([device isFlashModeSupported:flashMode]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        } else {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}

- (BOOL)cameraHasTorch {
    return [[self activeDevice] hasTorch];
}

- (AVCaptureTorchMode)torchMode {
    return [[self activeDevice] torchMode];
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode {
    AVCaptureDevice *device = [self activeDevice];
    if ([device isTorchModeSupported:torchMode]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.torchMode = torchMode;
            [device unlockForConfiguration];
        } else {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
}

#pragma mark - 图片捕获
- (void)captureStillImage {
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = 0;
    }
    
    id handler = ^(CMSampleBufferRef sampleBuffer , NSError *error) {
        if (sampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            dispatch_async(dispatch_get_main_queue(), ^{
               [[NSNotificationCenter defaultCenter] postNotificationName:@"THThumbnailCreatedNotification" object:image];
            });
        }
    };
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
}

- (AVCaptureVideoOrientation)currentVideoOrientation {
    AVCaptureVideoOrientation orientation;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait:
            orientation = UIDeviceOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientation = UIDeviceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = UIDeviceOrientationLandscapeLeft;
            break;
        default:
            orientation = UIDeviceOrientationPortraitUpsideDown;
            break;
    }
    return orientation;
}

- (void)writeImageToAssetLibrary:(UIImage *)image {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(NSInteger)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (!error) {
            //写入成功
            NSLog(@"图片保存成功");
        } else {
            
        }
    }];
}

#pragma mark - 视频捕获
- (BOOL)isMovieRecording {
    return self.movieOutput.isRecording;
}

- (void)startMovieRecording {
    if (![self isMovieRecording]) {
        AVCaptureConnection *connection = [self.movieOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([connection isVideoOrientationSupported]) {
             connection.videoOrientation = [self currentVideoOrientation];
        }
        if ([connection isVideoStabilizationSupported]) {
            connection.enablesVideoStabilizationWhenAvailable = YES;
        }
        AVCaptureDevice *device = [self activeDevice];
        if (device.isSmoothAutoFocusSupported) {
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                device.smoothAutoFocusEnabled = YES;
                [device unlockForConfiguration];
            } else {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }
        self.outputURL = [self uniqueURL];
        [self.movieOutput startRecordingToOutputFileURL:self.outputURL recordingDelegate:self];
    }
}

- (void)stopMovideRecording {
    if ([self isMovieRecording]) {
        [self.movieOutput stopRecording];
    }
}

- (NSURL *)uniqueURL {
    NSString *dir = NSTemporaryDirectory();
    if (dir) {
       NSString *filePath = [dir stringByAppendingPathComponent:@"video.mp4"];
        return [NSURL fileURLWithPath:filePath];
    }
    return nil;
}

#pragma mark - reverse video
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)activeDevice {
    return self.activeVideoInput.device;
}

- (AVCaptureDevice *)inactiveDevice {
    AVCaptureDevice *device = nil;
    if (self.cameraCount > 1) {
        if ([self activeDevice].position == AVCaptureDevicePositionBack) {
            device = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }else {
            device = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
    }
    return device;
}

#pragma mark - AVCaptureFileOutputDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    if (error) {
        [self.delegate mediaCaptureFailedWithError:error];
    } else {
        //保存捕获的视频
        [self writeVideoToAssetLibrary:self.outputURL];
    }
    self.outputURL = nil;
}

- (void)writeVideoToAssetLibrary:(NSURL *)videoURL {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoURL]) {
        ALAssetsLibraryWriteVideoCompletionBlock completionBlock;
        completionBlock = ^(NSURL *assetURL , NSError *error) {
            if (!error) {
                [self generateThumbnailForVideoAtURL:videoURL];
            } else {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        };
        [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:completionBlock];
    }
}

- (void)generateThumbnailForVideoAtURL:(NSURL *)videoURL {
    dispatch_async(self.videoQueue, ^{
        AVAsset *asset = [AVAsset assetWithURL:videoURL];
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        imageGenerator.maximumSize = CGSizeMake(50.0, 50.f);
        imageGenerator.appliesPreferredTrackTransform = YES;
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:nil];
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"发送消息");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"THThumbnailCreatedNotification" object:image];
        });
        CGImageRelease(imageRef);
    });
}
@end

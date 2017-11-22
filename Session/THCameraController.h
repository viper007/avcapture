//
//  THCameraController.h
//  Session
//
//  Created by lvzhenhua on 2017/11/18.
//  Copyright © 2017年 lvzhenhua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
extern NSString *const THThumbnailCreatedNotification;

@protocol THCameraControllerDelegate <NSObject>

- (void)deviceConfigurationFailedWithError:(NSError *)error;
- (void)mediaCaptureFailedWithError:(NSError *)error;
- (void)assetLibraryWriteFailedWithError:(NSError *)error;

@end


@interface THCameraController : NSObject

@property (nonatomic ,weak) id<THCameraControllerDelegate> delegate;
@property (nonatomic ,strong, readonly) AVCaptureSession *captureSession;
//session Configue
- (BOOL)setupSession:(NSError *)error;
- (void)startSession;
- (void)stopSession;

//camera device Support
- (BOOL)switchCameras;
- (BOOL)canSwitchCameras;
@property (nonatomic ,readonly) NSUInteger cameraCount;
@property (nonatomic ,readonly) BOOL cameraHasTorch;
@property (nonatomic ,readonly) BOOL cameraHasFlash;
@property (nonatomic ,readonly) BOOL cameraSupportsTapToFocus;
@property (nonatomic ,readonly) BOOL cameraSupportsTapToExpose;
@property (nonatomic) AVCaptureTorchMode torchMode;
@property (nonatomic) AVCaptureFlashMode flashMode;
@property (nonatomic) AVCaptureFocusMode focusMode;

//tap to * methods
- (void)focusAtPoint:(CGPoint)point;
- (void)exposeAtPoint:(CGPoint)point;
- (void)resetFocusAndExposeModes;

/** Media Capture Methods */
- (void)captureStillImage;

/** Video Recording */
/** image */
//- (void)startRecording;
//- (void)stopRecording;
/** video */
- (BOOL)isMovieRecording;
- (void)startMovieRecording;
- (void)stopMovideRecording;

@end

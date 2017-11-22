//
//  THPreview.m
//  Session
//
//  Created by lvzhenhua on 2017/11/18.
//  Copyright © 2017年 lvzhenhua. All rights reserved.
//

#import "THPreview.h"

@implementation THPreviewView

#pragma mark - init
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
      [self setupView];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    //设置一些对应的画面
}

#pragma mark - baseConfig
+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (void)setSession:(AVCaptureSession *)session {
    [(AVCaptureVideoPreviewLayer *)self.layer setSession:session];
    [(AVCaptureVideoPreviewLayer *)self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (AVCaptureSession *)session {
    return [(AVCaptureVideoPreviewLayer *)self.layer session];
}

/**
 将屏幕上的点映射到摄像头上的点
 @param point 点击的屏幕上的点
 @return 返回到摄像头上的点
 */
- (CGPoint)captureDevicePointForPoint:(CGPoint)point {
    AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
    return [layer captureDevicePointOfInterestForPoint:point];
}

@end

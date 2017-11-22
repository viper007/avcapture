 //
//  THPreview.h
//  Session
//
//  Created by lvzhenhua on 2017/11/18.
//  Copyright © 2017年 lvzhenhua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol THPreviewViewDelegate <NSObject>

- (void)tapedToFoucsAtPoint:(CGPoint)point ;
- (void)tpaedToExposeAtPoint:(CGPoint)point ;
- (void)tapedToResetFoucsAndExpose ;

@end

@interface THPreviewView : UIView

@property (nonatomic ,strong) AVCaptureSession *session ;
@property (nonatomic ,weak) id<THPreviewViewDelegate> delegate ;

@property (nonatomic ,assign) BOOL tapToFocusEnabled ;
@property (nonatomic ,assign) BOOL tapToExposeEnabled ;

@end

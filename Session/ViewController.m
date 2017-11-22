//
//  ViewController.m
//  Session
//
//  Created by lvzhenhua on 2017/11/18.
//  Copyright © 2017年 lvzhenhua. All rights reserved.
//

#import "ViewController.h"
#import "THCameraController.h"
#import "THPreview.h"

@interface ViewController ()

@property (nonatomic ,strong) THCameraController *cameraController;
@property (weak, nonatomic) IBOutlet THPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *showButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showImage:) name:@"THThumbnailCreatedNotification" object:nil];
    //
    self.cameraController = [[THCameraController alloc] init];
    NSError *error;
    if ([self.cameraController setupSession:error]) {
        [self.previewView setSession:self.cameraController.captureSession];
        [self.cameraController startSession];
    } else {
        NSLog(@"error:%@",[error localizedDescription]);
    }
}


- (void)showImage:(NSNotification *)note {
    UIImage *image = (UIImage *)note.object;
    [self.showButton setBackgroundImage:image forState:UIControlStateNormal];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return true;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation ViewController (recordControl)

- (IBAction)swotchCameras:(id)sender {
    [self.cameraController switchCameras];
}
- (IBAction)startRecord:(UIButton *)sender {
    [self.cameraController startMovieRecording];
}
- (IBAction)saveRecord:(UIButton *)sender forEvent:(UIEvent *)event {
    [self.cameraController stopMovideRecording];
}
- (IBAction)capturePhoto:(UIButton *)sender {
    [self.cameraController captureStillImage];
}

@end

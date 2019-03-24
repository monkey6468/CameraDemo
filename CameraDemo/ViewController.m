//
//  ViewController.m
//  CameraDemo
//
//  Created by XWH on 2019/3/24.
//  Copyright © 2019 XWH. All rights reserved.
//

#import "ViewController.h"
#import "WHCamera.h"

@interface ViewController ()<WHCameraDelegate>

@property (strong, nonatomic) WHCamera *camera;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.camera = [[WHCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480
                                                 delegate:self
                                    captureDevicePosition:AVCaptureDevicePositionFront
                                                inSubView:self.view
                                                 depthTag:YES
                                              adaptCamera:YES
                                                 portrait:NO
                                              fillPreView:YES];
    [self.camera startCamera];
}
- (void)dealloc
{
    [self.camera releaseCamera];
}

#pragma mark - WHCameraDelegate

- (void)whCamera:(WHCamera *)whCamera didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"%s",__func__);
}

- (void)whCamera:(WHCamera *)whCamera didOutputSyncedSampleBufferData:(AVCaptureSynchronizedSampleBufferData *)syncedSampleBufferData syncedDepthBufferData:(AVCaptureSynchronizedDepthData *)syncedDepthBufferData
API_AVAILABLE(ios(11.0)){
    NSLog(@"%s",__func__);
}

@end

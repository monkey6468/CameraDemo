//
//  WHCameraPreview.m
//  CameraDemo
//
//  Created by xwh on 2019/2/14.
//  Copyright © 2019年 xwh. All rights reserved.
//

#import "WHCameraPreview.h"

@implementation WHCameraPreview

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    return previewLayer.session;
}

- (void)setSessionPreset:(NSString *)sessionPreset
{
    _sessionPreset = sessionPreset;
}

- (void)setSession:(AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.session = session;
    previewLayer.session.sessionPreset = self.sessionPreset;
}

@end

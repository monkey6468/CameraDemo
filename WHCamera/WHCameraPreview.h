//
//  WHCameraPreview.h
//  CameraDemo
//
//  Created by xwh on 2019/2/14.
//  Copyright © 2019年 xwh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVCaptureSession;
@interface WHCameraPreview : UIImageView

@property (nonatomic) AVCaptureSession *session;
@property (copy, nonatomic) NSString *sessionPreset;

@end

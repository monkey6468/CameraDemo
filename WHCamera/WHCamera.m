//
//  WHCamera.m
//  CameraDemo
//
//  Created by xwh on 2019/2/14.
//  Copyright © 2019 xwh. All rights reserved.
//

#import "WHCamera.h"
#import <sys/utsname.h>

#define IS_IPAD             ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#define STCameraWeakSelf __weak typeof(self) weakSelf = self;

static float GetPreviewFrameAndScale(NSString *strPreset,
                                     UIDeviceOrientation deviceOrientation,
                                     float fScreenWidth,
                                     float fScreenHeight,
                                     float *fPreviewWPtr,
                                     float *fPreviewHPtr,
                                     BOOL bFillPreView);

API_AVAILABLE(ios(11.0))
@interface WHCamera ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureDataOutputSynchronizerDelegate>
{
    float _fScale;
    float _fPreviewW;
    float _fPreviewH;
}
@property (strong, nonatomic) UIView *viewSuper;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (strong, nonatomic) AVCaptureDevice *deviceVideo;
@property (strong, nonatomic) AVCaptureDeviceInput *captureDeviceInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureDepthDataOutput *depthDataOutput;
@property (strong, nonatomic) AVCaptureDataOutputSynchronizer *outputSynchronizer;

@property (nonatomic, assign) UIDeviceOrientation iDeviceOrientation;
@property (nonatomic, assign) AVCaptureVideoOrientation captureVideoOrientation;
@property (nonatomic, assign) BOOL isGetImage;
@property (nonatomic, assign) BOOL bEnabledDepth;
@property (nonatomic, assign) BOOL bAdaptCamera;
@property (nonatomic, assign) BOOL bPortrait;
@property (nonatomic, assign) id<WHCameraDelegate> delegate;

@property (nonatomic, copy) WHCameraImageBlock blockImage;
@end

@implementation WHCamera

- (instancetype)initWithSessionPreset:(NSString *)strPreset
                             delegate:(id)stCameraDelegate
                captureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition
                            inSubView:(UIView *)view
                             depthTag:(BOOL)bEnabledDepth
                          adaptCamera:(BOOL)bAdaptCamera
                             portrait:(BOOL)bPortrait
                          fillPreView:(BOOL)bFillPreView
{
    if (self = [super init])
    {
        self.bFillPreView = bFillPreView;
        self.delegate = stCameraDelegate;
        self.bEnabledDepth = bEnabledDepth;
        self.bAdaptCamera = bAdaptCamera;
        self.bPortrait = bPortrait;
        
        self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
        self.captureDevicePosition = captureDevicePosition;
        self.viewSuper = view;
        
        self.preViewView = [[WHCameraPreview alloc]init];
        self.preViewView.sessionPreset = strPreset;
        [view addSubview:self.preViewView];
        
        if (self.bPortrait)
        {
            self.iDeviceOrientation = UIDeviceOrientationPortrait;
        }else
        {
            self.iDeviceOrientation = [WHCamera getDeviceOrientation];
        }

        _fScale = GetPreviewFrameAndScale(strPreset,
                                          self.iDeviceOrientation,
                                          view.frame.size.width,
                                          view.frame.size.height,
                                          &_fPreviewW,
                                          &_fPreviewH,
                                          self.bFillPreView);
        
        self.preViewView.bounds = CGRectMake(0, 0, _fPreviewW, _fPreviewH);
        self.preViewView.center = CGPointMake(self.viewSuper.frame.size.width * 0.5, self.viewSuper.frame.size.height * 0.5);
        self.preViewView.userInteractionEnabled = YES;
        
        // init session
        if (self.session == nil) {
            self.session = [[AVCaptureSession alloc] init];
            self.preViewView.session = self.session;
        }
        
        [self configCameraPosition:self.captureDevicePosition
                             bInit:YES
                             block:^(BOOL bResult) {
                                 
                             }];
    }
    return self;
}

- (AVCaptureDevice *)getDeviceVideo
{
    self.deviceVideo = [self getCameraDeviceWithPosition:self.captureDevicePosition];
    return self.deviceVideo;
}

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position
{
    if (self.bAdaptCamera)
    {
        if (@available(iOS 11.1, *))
        {
            AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInTrueDepthCamera] mediaType:AVMediaTypeVideo position:position];
            for (AVCaptureDevice *device in dissession.devices)
            {
                if ([device position] == position)
                {
                    self.bEnabledDepth = YES;
                    return device;
                }
            }
        }
        else
        {
            self.bEnabledDepth = NO;
            NSLog(@"iPhoneX至少需要iOS11.1系统");
        }
        
        if (@available(iOS 10.0, *))
        {
            AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
            for (AVCaptureDevice *device in dissession.devices)
            {
                if ([device hasMediaType:AVMediaTypeVideo])
                {
                    if ([device position] == position)
                    {
                        self.bEnabledDepth = NO;
                        return device;
                    }
                }
            }
        }
        else
        {
            // Fallback on earlier versions
            NSArray *devices = [AVCaptureDevice devices];
            for (AVCaptureDevice *device in devices)
            {
                if ([device hasMediaType:AVMediaTypeVideo])
                {
                    if ([device position] == position)
                    {
                        self.bEnabledDepth = NO;
                        return device;
                    }
                }
            }
        }
        
        return nil;
    }
    else
    {
        if (self.bEnabledDepth)
        {
            if (@available(iOS 11.1, *))
            {
                AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInTrueDepthCamera] mediaType:AVMediaTypeVideo position:position];
                for (AVCaptureDevice *device in dissession.devices)
                {
                    if ([device position] == position)
                    {
                        self.bEnabledDepth = YES;
                        return device;
                    }
                }
            }
            else
            {
                NSLog(@"iPhoneX至少需要iOS11.1系统");
            }
            
            if (@available(iOS 10.0, *)) {
                AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
                for (AVCaptureDevice *device in dissession.devices)
                {
                    if ([device hasMediaType:AVMediaTypeVideo])
                    {
                        if ([device position] == position)
                        {
                            self.bEnabledDepth = NO;
                            return device;
                        }
                    }
                }
            }
            else
            {
                // Fallback on earlier versions
                NSArray *devices = [AVCaptureDevice devices];
                for (AVCaptureDevice *device in devices)
                {
                    if ([device hasMediaType:AVMediaTypeVideo])
                    {
                        if ([device position] == position)
                        {
                            self.bEnabledDepth = NO;
                            return device;
                        }
                    }
                }
            }
        }
        else
        {
            if (@available(iOS 10.0, *))
            {
                AVCaptureDeviceDiscoverySession *dissession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
                for (AVCaptureDevice *device in dissession.devices)
                {
                    if ([device hasMediaType:AVMediaTypeVideo])
                    {
                        if ([device position] == position)
                        {
                            self.bEnabledDepth = NO;
                            return device;
                        }
                    }
                }
            }
            else
            {
                // Fallback on earlier versions
                NSArray *devices = [AVCaptureDevice devices];
                for (AVCaptureDevice *device in devices)
                {
                    if ([device hasMediaType:AVMediaTypeVideo])
                    {
                        if ([device position] == position)
                        {
                            self.bEnabledDepth = NO;
                            return device;
                        }
                    }
                }
            }
        }
        return nil;
    }
}

- (void)startCamera
{
    [self.session startRunning];
}

- (void)stopCamera
{
    [self.session stopRunning];
}

- (void)releaseCamera
{
    [self.videoDataOutput setSampleBufferDelegate:nil queue:self.sessionQueue];
    [self.outputSynchronizer setDelegate:nil queue:self.sessionQueue];
    [self.depthDataOutput setDelegate:nil callbackQueue:self.sessionQueue];
    if (self.session.isRunning)
    {
        [self.session stopRunning];
//        self.session = nil;
    }
}

#pragma mark - 改变摄像头配置

- (void)configCameraPosition:(AVCaptureDevicePosition)position
                       bInit:(BOOL)bInit
                       block:(WHCameraBlock)block
{
    if (self.session.isRunning)
    {
        [self.session stopRunning];
        [self.session beginConfiguration];
    }

    // video orientation
    if (self.bPortrait)
    {
        self.captureVideoOrientation = AVCaptureVideoOrientationPortrait;
    }else
    {
        self.captureVideoOrientation = [WHCamera getCaptureVideoOrientation];
    }
    
    if (bInit) {
        [self reConfigCameraisInit:bInit
                             block:block];
    }else {
        // 设置线程的原因是，可能存在快速切换的问题
        STCameraWeakSelf
        dispatch_async(self.sessionQueue, ^{
            [weakSelf reConfigCameraisInit:bInit
                                     block:block];
        });
    }
}

- (void)reConfigCameraisInit:(BOOL)bInit
                       block:(WHCameraBlock)block
{
    if (self.captureDeviceInput)
    {
        [self.session removeInput:self.captureDeviceInput];
    }

    // video output
    if (self.videoDataOutput)
    {
        [self.session removeOutput:self.videoDataOutput];
    }
    
    // depth output
    if (self.bAdaptCamera)
    {
        if (self.depthDataOutput)
        {
            [self.session removeOutput:self.depthDataOutput];
            self.depthDataOutput = nil;
        }
    }
    else
    {
        if (self.bEnabledDepth)
        {
            if (self.depthDataOutput)
            {
                [self.session removeOutput:self.depthDataOutput];
                self.depthDataOutput = nil;
            }
        }
    }
    

    // device iuput
    NSError *error = nil;
    self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[self getDeviceVideo] error:&error];

    if (error)
    {
        NSLog(@"changeCameraPosition ERROR: trying to open camera: %@", error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(NO);
        });
        return;
    }
    else
    {
        // out data mirror
        BOOL bMirrored = self.deviceVideo.position == AVCaptureDevicePositionFront ? YES:NO;
        
        // device input
        if ([self.session canAddInput:self.captureDeviceInput])
        {
            [self.session addInput:self.captureDeviceInput];
        }
        
        // video output
        if (self.videoDataOutput == nil)
        {
            self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
            [self.videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        }
        if ([self.session canAddOutput:self.videoDataOutput])
        {
            [self.session addOutput:self.videoDataOutput];
            [self.videoDataOutput setSampleBufferDelegate:self queue:self.sessionQueue];
            [self resetPreViewOrientation];
        }
        AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        [videoConnection setVideoOrientation:self.captureVideoOrientation];
        [videoConnection setVideoMirrored:bMirrored];

        // depth output
        if (self.bAdaptCamera)
        {
            if ([WHCamera isSupportDepthDataCameraPosition:self.captureDevicePosition preset:self.session.sessionPreset])
            {
                if (@available(iOS 11.0, *)) {
                    if (self.depthDataOutput == nil) {
                        self.depthDataOutput = [[AVCaptureDepthDataOutput alloc] init];
                    }
                    if ([self.session canAddOutput:self.depthDataOutput])
                    {
                        [self.session addOutput:self.depthDataOutput];
                    }
                    AVCaptureConnection *depthConnection = [self.depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
                    [depthConnection setVideoOrientation:self.captureVideoOrientation];
                    [depthConnection setVideoMirrored:bMirrored];
                    
                    if (depthConnection) {
                        // add outputSynchronizer
                        self.outputSynchronizer = [[AVCaptureDataOutputSynchronizer alloc] initWithDataOutputs:@[self.videoDataOutput, self.depthDataOutput]];
                        [self.outputSynchronizer setDelegate:self queue:self.sessionQueue];
                        self.bEnabledDepth = YES;
                    }else
                    {
                        self.bEnabledDepth = NO;
                    }
                    
                } else {
                    // Fallback on earlier versions
                    self.bEnabledDepth = NO;
                }
            }else
            {
                self.bEnabledDepth = NO;
            }
        }
        else
        {
            if (self.bEnabledDepth)
            {
                if ([WHCamera isSupportDepthDataCameraPosition:self.captureDevicePosition preset:self.session.sessionPreset])
                {
                    if (@available(iOS 11.0, *)) {
                        if (self.depthDataOutput == nil) {
                            self.depthDataOutput = [[AVCaptureDepthDataOutput alloc] init];
                        }
                        if ([self.session canAddOutput:self.depthDataOutput])
                        {
                            [self.session addOutput:self.depthDataOutput];
                        }
                        AVCaptureConnection *depthConnection = [self.depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
                        [depthConnection setVideoOrientation:self.captureVideoOrientation];
                        [depthConnection setVideoMirrored:bMirrored];
                        
                        if (depthConnection) {
                            // add outputSynchronizer
                            self.outputSynchronizer = [[AVCaptureDataOutputSynchronizer alloc] initWithDataOutputs:@[self.videoDataOutput, self.depthDataOutput]];
                            [self.outputSynchronizer setDelegate:self queue:self.sessionQueue];
                            self.bEnabledDepth = YES;
                        }else
                        {
                            self.bEnabledDepth = NO;
                        }
                        
                    } else {
                        // Fallback on earlier versions
                        self.bEnabledDepth = NO;
                    }
                }else
                {
                    self.bEnabledDepth = NO;
                }
            }
        }
        
        [self.session commitConfiguration];
        if (bInit == NO) {
            [self.session startRunning];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            block(YES);
        });
    }
}

#pragma mark - 改变摄像头的配置:摄像头位置、分辨率、深度

- (void)changeCameraPosition:(AVCaptureDevicePosition)position
               sessionPreset:(NSString *)strPreset
                    depthTag:(BOOL)bEnabledDepth
                 adaptCamera:(BOOL)bAdaptCamera
                       block:(WHCameraBlock)block
{
    if (self.session.isRunning)
    {
        [self.session stopRunning];
        [self.session beginConfiguration];
    }
    
    self.captureDevicePosition = position;
    self.bEnabledDepth = bEnabledDepth;
    self.bAdaptCamera = bAdaptCamera;
    
    // 移除代理
    [self.videoDataOutput setSampleBufferDelegate:nil queue:self.sessionQueue];
    [self.outputSynchronizer setDelegate:nil queue:self.sessionQueue];
    [self.depthDataOutput setDelegate:nil callbackQueue:self.sessionQueue];

    if (![strPreset isEqualToString:self.session.sessionPreset])
    {
        if ([self.session canSetSessionPreset:strPreset])
        {
            self.session.sessionPreset = strPreset;
            _fScale = GetPreviewFrameAndScale(strPreset,
                                              self.iDeviceOrientation,
                                              self.viewSuper.frame.size.width,
                                              self.viewSuper.frame.size.height,
                                              &_fPreviewW,
                                              &_fPreviewH,
                                              self.bFillPreView);
            // change preview
            self.preViewView.bounds = CGRectMake(0, 0, _fPreviewW, _fPreviewH);
            self.preViewView.center = CGPointMake(self.viewSuper.frame.size.width * 0.5, self.viewSuper.frame.size.height * 0.5);
        }
    }else {
        NSLog(@"changeSessionPreset error : 分辨率相同设置");
    }
    
    STCameraWeakSelf
    dispatch_async(self.sessionQueue, ^{
        [weakSelf reConfigCameraisInit:NO
                                 block:block];
    });
}

#pragma mark - 重新调整视频预览Frame

- (void)resetPreviewFrameWithScreenWidth:(float)fScreenWidth
                            screenHeight:(float)fScreenHeight
{
    if (self.bPortrait)
    {
        self.iDeviceOrientation = UIDeviceOrientationPortrait;
    }else
    {
        self.iDeviceOrientation = [WHCamera getDeviceOrientation];
    }
    
    _fScale = GetPreviewFrameAndScale(self.session.sessionPreset,
                                      self.iDeviceOrientation,
                                      fScreenWidth,
                                      fScreenHeight,
                                      &_fPreviewW,
                                      &_fPreviewH,
                                      self.bFillPreView);
    
    self.preViewView.bounds = CGRectMake(0, 0, _fPreviewW, _fPreviewH);
    self.preViewView.center = CGPointMake(fScreenWidth * 0.5, fScreenHeight * 0.5);
}

- (void)resetSession
{
    [self resetCaptureVideoOrientation];
    [self resetPreViewOrientation];
}

#pragma mark - 重置预览方向

- (void)resetPreViewOrientation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.preViewView.layer;
        previewLayer.connection.videoOrientation = self.captureVideoOrientation;
    });
}

#pragma mark - 重置视频流数据输出方向

- (void)resetCaptureVideoOrientation
{
    BOOL bMirrored = self.deviceVideo.position == AVCaptureDevicePositionFront ? YES:NO;
    if (self.bPortrait)
    {
        self.captureVideoOrientation = AVCaptureVideoOrientationPortrait;
    }else
    {
        self.captureVideoOrientation = [WHCamera getCaptureVideoOrientation];
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (self.session.isRunning)
        {
            [self.session stopRunning];
            [self.session beginConfiguration];
        }
        AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        [videoConnection setVideoOrientation:self.captureVideoOrientation];
        [videoConnection setVideoMirrored:bMirrored];
        
        if (self.bAdaptCamera)
        {
            if ([WHCamera isSupportDepthDataCameraPosition:self.captureDevicePosition preset:self.session.sessionPreset])
            {
                if (@available(iOS 11.0, *)) {
                    AVCaptureConnection *depthConnection = [self.depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
                    [depthConnection setVideoOrientation:self.captureVideoOrientation];
                    [depthConnection setVideoMirrored:bMirrored];
                } else {
                    // Fallback on earlier versions
                }
            }
        }
        else
        {
            if (self.bEnabledDepth)
            {
                if (@available(iOS 11.0, *)) {
                    AVCaptureConnection *depthConnection = [self.depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
                    [depthConnection setVideoOrientation:self.captureVideoOrientation];
                    [depthConnection setVideoMirrored:bMirrored];
                } else {
                    // Fallback on earlier versions
                }
            }
        }
        
        if (self.session.isRunning == NO)
        {
            [self.session commitConfiguration];
            [self.session startRunning];
        }
    });
}

#pragma mark - 是否支持深度摄像头

+ (BOOL)isSupportDepthDataCameraPosition:(AVCaptureDevicePosition)position
                                  preset:(NSString *)strPreset
{
    NSString *strDeviceModel = [self getDeviceModel];
    NSRange rangeiPad8 = [strDeviceModel rangeOfString:@"iPad8"];// 带深度的iPad Pro
    NSRange rangeiPhone10_3 = [strDeviceModel rangeOfString:@"iPad8"];//iPhone XR
    NSRange rangeiPhone10_6 = [strDeviceModel rangeOfString:@"iPad8"];//iPhone XR
    NSRange rangeiPhone11_2 = [strDeviceModel rangeOfString:@"iPad8"];//iPhone XS
    NSRange rangeiPhone11_6 = [strDeviceModel rangeOfString:@"iPad8"];//iPhone XS Max

    if ((rangeiPad8.location != NSNotFound)// 带深度的iPad Pro
        ||(rangeiPhone10_3.location != NSNotFound)//iPhone XR
        ||(rangeiPhone10_6.location != NSNotFound)//iPhone XR
        ||(rangeiPhone11_2.location != NSNotFound)//iPhone XS
        ||(rangeiPhone11_6.location != NSNotFound)//iPhone XS Max
        )
    {
        if ([strPreset isEqualToString:AVCaptureSessionPreset640x480]
            && position == AVCaptureDevicePositionFront)
        {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)getDeviceModel
{
    // https://www.theiphonewiki.com/wiki/Models#iPhone
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *strDevicdModel = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    return strDevicdModel;
}

#pragma mark - 获取视频流数据输出方向

+ (AVCaptureVideoOrientation)getCaptureVideoOrientation
{
    UIDeviceOrientation iDeviceOrientation = [self getDeviceOrientation];
    AVCaptureVideoOrientation captureVideoOrientation = AVCaptureVideoOrientationPortrait;
    switch (iDeviceOrientation) {
        case UIDeviceOrientationPortrait:   // Device oriented vertically, home button on the bottom
            captureVideoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            captureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            captureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            captureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            break;
    }
    return captureVideoOrientation;
}

#pragma mark - 获取设备方向

+ (UIDeviceOrientation)getDeviceOrientation
{
    // Apple建议不要使用设备方向进行视图布局。
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    switch (deviceOrientation)
    {
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            deviceOrientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
            break;
        default:
            break;
    }
    return deviceOrientation;
}

#pragma mark -
#pragma mark - setting method

- (void)setBFillPreView:(BOOL)bFillPreView
{
    _bFillPreView = bFillPreView;
}

#pragma mark -
#pragma mark - getting method

- (float)fScale
{
    return _fScale;
}
- (WHCameraPreview *)preViewView
{
    return _preViewView;
}

- (float)fPreViewH
{
    return _fPreviewH;
}
- (float)fPreViewW
{
    return _fPreviewW;
}

- (AVCaptureDevicePosition)captureDevicePosition
{
    return _captureDevicePosition;
}
- (UIDeviceOrientation)iDeviceOrientation
{
    return _iDeviceOrientation;
}

+ (NSString *)getCaptureSessionPreset:(NSString *)strSessionPreset
{
    if ([strSessionPreset isEqualToString:@"640x480"])
    {
        return AVCaptureSessionPreset640x480;
    }else if ([strSessionPreset isEqualToString:@"1280x720"])
    {
        return  AVCaptureSessionPreset1280x720;
    }else if ([strSessionPreset isEqualToString:@"1920x1080"])
    {
        return AVCaptureSessionPreset1920x1080;
    }else{
        return AVCaptureSessionPreset640x480;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"systemPressureState"])
    {
        if (@available(iOS 11.1, *)) {
            AVCaptureSystemPressureLevel level = self.deviceVideo.systemPressureState.level;
            int recommendedFrameRate = 30;
            if (level == AVCaptureSystemPressureLevelNominal) {
                recommendedFrameRate = 30;
            }else if (level == AVCaptureSystemPressureLevelFair) {
                recommendedFrameRate = 24;
            }else if (level == AVCaptureSystemPressureLevelSerious) {
                recommendedFrameRate = 24;
            }else if (level == AVCaptureSystemPressureLevelCritical) {
                recommendedFrameRate = 15;
            }else if (level == AVCaptureSystemPressureLevelShutdown) {
                //            return;
            }
            NSError *err = nil;
            [self.deviceVideo lockForConfiguration:&err];
            if (err) {
                NSLog(@"err : %@",err);
            }
            NSLog(@"System pressure state is now \(%@). Will set frame rate to \(%d)",level,recommendedFrameRate);
            self.deviceVideo.activeVideoMinFrameDuration = CMTimeMake(1, recommendedFrameRate);
            self.deviceVideo.activeVideoMaxFrameDuration = CMTimeMake(1, recommendedFrameRate);
            [self.deviceVideo unlockForConfiguration];
        }
    }
}


- (void)dealloc
{
    NSLog(@"%s",__func__);
}

#pragma mark -
#pragma mark - AVCaptureDataOutputSynchronizerDelegate

- (void)dataOutputSynchronizer:(nonnull AVCaptureDataOutputSynchronizer *)synchronizer didOutputSynchronizedDataCollection:(nonnull AVCaptureSynchronizedDataCollection *)synchronizedDataCollection
API_AVAILABLE(ios(11.0)){
    AVCaptureSynchronizedData *syncedVideoData = [synchronizedDataCollection synchronizedDataForCaptureOutput:self.videoDataOutput];
    AVCaptureSynchronizedData *syncedDepthData =[synchronizedDataCollection synchronizedDataForCaptureOutput:self.depthDataOutput];
    
    AVCaptureSynchronizedSampleBufferData *syncedSampleBufferData = (AVCaptureSynchronizedSampleBufferData *)syncedVideoData;
    AVCaptureSynchronizedDepthData *syncedDepthBufferData = (AVCaptureSynchronizedDepthData *)syncedDepthData;

    if ([self.delegate respondsToSelector:@selector(whCamera:didOutputSyncedSampleBufferData:syncedDepthBufferData:)])
    {
        [self.delegate whCamera:self didOutputSyncedSampleBufferData:syncedSampleBufferData syncedDepthBufferData:syncedDepthBufferData];
    }

    CMSampleBufferRef sampleBuffer = syncedSampleBufferData.sampleBuffer;
    // 获取图片
    [self getPictureFromSampleBuffer:sampleBuffer];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if ([self.delegate respondsToSelector:@selector(whCamera:didOutputSampleBuffer:)])
    {
        [self.delegate whCamera:self didOutputSampleBuffer:sampleBuffer];
    }
    
    // 获取图片
    [self getPictureFromSampleBuffer:sampleBuffer];
}

- (void)getPictureFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (self.isGetImage)
    {
        self.isGetImage = NO;
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        UIImage *imageSampleBuffer = [WHCamera trasformToImageFromSampleBuffer:sampleBuffer];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *imageResult = [WHCamera imageRotationOrientation:imageSampleBuffer];
            self.blockImage(imageResult);
        });
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
}

- (void)takePhoto:(WHCameraImageBlock)block
{
    self.isGetImage = YES;
    self.blockImage = block;
}

+ (UIImage *)imageRotationOrientation:(UIImage *)image
{
    UIImage *imageNormailzed = [self fixOrientation:image];
    UIImage *imageResult = [self image:imageNormailzed rotate:UIImageOrientationLeft];
    return imageResult;
}

#pragma mark -
#pragma mark - image methods

+ (UIImage *)fixOrientation:(UIImage *)image
{
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp)
        return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation)
    {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (image.imageOrientation)
    {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation)
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+ (UIImage *)image:(UIImage *)image
            rotate:(UIImageOrientation)orientation
{
    CGRect bnds = CGRectZero;
    UIImage* copy = nil;
    CGContextRef ctxt = nil;
    CGImageRef imag = image.CGImage;
    CGRect rect = CGRectZero;
    CGAffineTransform tran = CGAffineTransformIdentity;
    
    rect.size.width = CGImageGetWidth(imag);
    rect.size.height = CGImageGetHeight(imag);
    
    bnds = rect;
    
    switch (orientation){
            
        case UIImageOrientationUp:
            return image;
            
        case UIImageOrientationUpMirrored:
            tran = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown:
            tran = CGAffineTransformMakeTranslation(rect.size.width,
                                                    rect.size.height);
            tran = CGAffineTransformRotate(tran, M_PI);
            break;
            
        case UIImageOrientationDownMirrored:
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.height);
            tran = CGAffineTransformScale(tran, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeft:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.width);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeftMirrored:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(rect.size.height,
                                                    rect.size.width);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRight:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(rect.size.height, 0.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeScale(-1.0, 1.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        default:
            return image;
    }
    
    UIGraphicsBeginImageContext(bnds.size);
    ctxt = UIGraphicsGetCurrentContext();
    
    switch (orientation){
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextScaleCTM(ctxt, -1.0, 1.0);
            CGContextTranslateCTM(ctxt, -rect.size.height, 0.0);
            break;
            
        default:
            CGContextScaleCTM(ctxt, 1.0, -1.0);
            CGContextTranslateCTM(ctxt, 0.0, -rect.size.height);
            break;
    }
    
    CGContextConcatCTM(ctxt, tran);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, imag);
    
    copy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return copy;
}

+ (UIImage *)trasformToImageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
    
    CGImageRelease(quartzImage);
    return image;
}

///交换宽和高
static CGRect swapWidthAndHeight(CGRect rect)
{
    CGFloat swap = rect.size.width;
    rect.size.width = rect.size.height;
    rect.size.height = swap;
    return rect;
}
@end

static float GetPreviewFrameAndScale(NSString *strPreset,
                                     UIDeviceOrientation deviceOrientation,
                                     float fScreenWidth,
                                     float fScreenHeight,
                                     float *fPreviewWPtr,
                                     float *fPreviewHPtr,
                                     BOOL bFillPreView)
{
    float fScale = 0;
    float fPreviewW = 0;
    float fPreviewH = 0;
    
    BOOL isPortrait = UIDeviceOrientationIsPortrait(deviceOrientation);
    
    BOOL bFill = bFillPreView;
    
    if ([strPreset isEqualToString:AVCaptureSessionPreset640x480])
    {
        if (isPortrait)
        {
            if (IS_IPAD) {
                fScale = 640 / fScreenHeight;
                fPreviewW = 480 / fScale;
                fPreviewH = fScreenHeight;
            }else {
                // iphone X
                if (bFill) {
                    fScale = 640 / fScreenHeight;
                    fPreviewW = 480 / fScale;
                    fPreviewH = fScreenHeight;
                }else {
                    fScale = 480 / fScreenWidth;
                    fPreviewH = 640 / fScale;
                    fPreviewW = fScreenWidth;
                }
            }
        }else
        {
            if (IS_IPAD) {
                fScale = 640 / fScreenWidth;
                fPreviewH = 480 / fScale;
                fPreviewW = fScreenWidth;
            }else {
                if (bFill) {
                    fScale = 640 / fScreenWidth;
                    fPreviewH = 480 / fScale;
                    fPreviewW = fScreenWidth;
                }else {
                    fScale = 480 / fScreenHeight;
                    fPreviewW = 640 / fScale;
                    fPreviewH = fScreenHeight;
                }
            }
        }
    }else if ([strPreset isEqualToString:AVCaptureSessionPreset1280x720])
    {
        if (isPortrait)
        {
            if (IS_IPAD)
            {
                if (bFill) {
                    fScale = 720 / fScreenWidth;
                    fPreviewH = 1280 / fScale;
                    fPreviewW = fScreenWidth;
                }else {
                    fScale = 1280 / fScreenHeight;
                    fPreviewW = 720 / fScale;
                    fPreviewH = fScreenHeight;
                }
            }else {
                if (bFill) {
                    fScale = 1280 / fScreenHeight;
                    fPreviewW = 720 / fScale;
                    fPreviewH = fScreenHeight;
                }else {
                    fScale = 720 / fScreenWidth;
                    fPreviewH = 1280 / fScale;
                    fPreviewW = fScreenWidth;
                }
            }
            
        }else
        {
            if (IS_IPAD) {
                if (bFill) {
                    fScale = 720 / fScreenHeight;
                    fPreviewW = 1280 / fScale;
                    fPreviewH = fScreenHeight;
                }else {
                    fScale = 1280 / fScreenWidth;
                    fPreviewH = 720 / fScale;
                    fPreviewW = fScreenWidth;
                }
            }else {
                if (bFill) {
                    fScale = 1280 / fScreenWidth;
                    fPreviewH = 720 / fScale;
                    fPreviewW = fScreenWidth;
                }else {
                    fScale = 720 / fScreenHeight;
                    fPreviewW = 1280 / fScale;
                    fPreviewH = fScreenHeight;
                }
            }
        }
    }else if ([strPreset isEqualToString:AVCaptureSessionPreset1920x1080])
    {
        if (isPortrait)
        {
            fScale = 1920 / fScreenHeight;
            fPreviewW = 1080 / fScale;
            fPreviewH = fScreenHeight;
        }else
        {
            fScale = 1080 / fScreenHeight;
            fPreviewW = 1920 / fScale;;
            fPreviewH = fScreenHeight;
        }
    }
    *fPreviewWPtr = fPreviewW;
    *fPreviewHPtr = fPreviewH;
    return fScale;
}

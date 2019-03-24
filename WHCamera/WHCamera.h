//
//  WHCamera.h
//  CameraDemo
//
//  Created by xwh on 2019/2/14.
//  Copyright © 2019 xwh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WHCameraPreview.h"

NS_ASSUME_NONNULL_BEGIN

@class WHCamera;
@protocol WHCameraDelegate <NSObject>

@required
- (void)whCamera:(WHCamera *)whCamera didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@required
/**
 深度数据使用需要如下判断，以免数据有误:
 
 CMSampleBufferRef sampleBuffer = syncedSampleBufferData.sampleBuffer;
 AVDepthData *depthData = syncedDepthBufferData.depthData;
 
 if(!syncedSampleBufferData.sampleBufferWasDropped
 && syncedSampleBufferData
 && !syncedDepthBufferData.depthDataWasDropped
 && syncedDepthBufferData)
 {
 [self didOutputSampleBuffer:sampleBuffer depthData:depthData];
 }
 */
- (void)whCamera:(WHCamera *)whCamera didOutputSyncedSampleBufferData:(AVCaptureSynchronizedSampleBufferData *)syncedSampleBufferData syncedDepthBufferData:(AVCaptureSynchronizedDepthData *)syncedDepthBufferData API_AVAILABLE(ios(11.0));

@end

typedef void(^WHCameraBlock)(BOOL bResult);
typedef void(^WHCameraImageBlock)(UIImage *image);

@interface WHCamera : NSObject

/// 摄像头的方向，AVCaptureDevicePosition
@property (assign, nonatomic) AVCaptureDevicePosition captureDevicePosition;
/// 摄像头会话
@property (strong, nonatomic) AVCaptureSession *session;

/// 设定预览界面需要充满屏幕,默认是NO
@property (assign, nonatomic) BOOL bFillPreView;

/// 获取设备的深度支持状态
@property (assign, nonatomic, readonly) BOOL bEnabledDepth;

/// 根据摄像头分辨率所获得 屏幕比例（屏幕/预览）
@property (assign, nonatomic, readonly) float fScale;
/// 获取设备的方向
@property (assign, nonatomic, readonly) UIDeviceOrientation iDeviceOrientation;
/// 根据摄像头分辨率所获得 预览界面宽度
@property (assign, nonatomic, readonly) float fPreViewW;
/// 根据摄像头分辨率所获得 预览界面高度
@property (assign, nonatomic, readonly) float fPreViewH;
/// 根据摄像头分辨率所获得 预览界面
@property (strong, nonatomic) WHCameraPreview *preViewView;

/**
 初始化摄像头的配置 需要注意的是，用完需要调用 "- (void)releaseCamera;" 函数释放，否则会因线程回调导致崩溃
 
 @param strPreset 分辨率 AVCaptureSessionPreset640x480、AVCaptureSessionPreset1280x720、AVCaptureSessionPreset1920x1080
 @param stCameraDelegate 视频的代理
 @param captureDevicePosition 摄像头的方向，AVCaptureDevicePosition
 @param view 所覆盖的界面
 @param bEnabledDepth 是否需要支持深度
 @param bPortrait 是否只支持竖屏
 @param bFillPreView 视频预览是否需要充满设备屏幕
 @return WHCamera
 */
- (instancetype)initWithSessionPreset:(NSString *)strPreset
                             delegate:(id)stCameraDelegate
                captureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition
                            inSubView:(UIView *)view
                             depthTag:(BOOL)bEnabledDepth
                          adaptCamera:(BOOL)bAdaptCamera
                             portrait:(BOOL)bPortrait
                          fillPreView:(BOOL)bFillPreView;

/**
 拍照获取正向图片

 @param block 结果回调
 */
- (void)takePhoto:(WHCameraImageBlock)block;

/**
 开启摄像头
 */
- (void)startCamera;

/**
 关闭摄像头
 */
- (void)stopCamera;

/**
 释放摄像头
 */
- (void)releaseCamera;

/**
 改变摄像头的配置

 @param position 摄像头位置
 @param strPreset 分辨率
 @param bEnabledDepth 深度
 @param bAdaptCamera 是否适应
 @param block 完成回调
 */
- (void)changeCameraPosition:(AVCaptureDevicePosition)position
               sessionPreset:(NSString *)strPreset
                    depthTag:(BOOL)bEnabledDepth
                 adaptCamera:(BOOL)bAdaptCamera
                       block:(WHCameraBlock)block;

/**
 根据设定字符串 获取分辨率 配置
 
 @param strSessionPreset 设定字符串
 @return 分辨率
 */
+ (NSString *)getCaptureSessionPreset:(NSString *)strSessionPreset;

/**
 设备旋转后,重新设定Session
 */
- (void)resetSession;

/**
 设备旋转后,重新设定视频预览
 
 @param fScreenWidth 当前屏幕的宽
 @param fScreenHeight 当前屏幕的高
 */
- (void)resetPreviewFrameWithScreenWidth:(float)fScreenWidth
                            screenHeight:(float)fScreenHeight;

/**
 是否支持深度摄像头

 @param position 摄像头位置
 @param strPreset 摄像头分辨率
 @return BOOL
 */
+ (BOOL)isSupportDepthDataCameraPosition:(AVCaptureDevicePosition)position
                                  preset:(NSString *)strPreset;

/**
 旋转图片的Orientation

 @param image 需要旋转的图片
 @return UIImage
 */
+ (UIImage *)imageRotationOrientation:(UIImage *)image;

/**
 获取设备方向
 
 @return 设备方向
 */
+ (UIDeviceOrientation)getDeviceOrientation;

@end

NS_ASSUME_NONNULL_END

# WHCamera
基于Object-C的iOS纯原生API相机，高度集成，使用快捷简单。可快速集成使用。最低支持iOS7的系统。


利用 AVCaptureDevice获取iOS端的硬件资源并取得相机资源，支持深度信息（AVDepth）获取、分辨率改变、前后摄像头切换、多方向旋转、摄像头预览改变等多种强大功能。

## 快速使用

1、导入头文件

```
#import "WHCamera.h"

```

2、声明全局变量并设置代理

```
@interface ViewController ()<WHCameraDelegate>

@property (strong, nonatomic) WHCamera *camera;

@end
```

3、直接初始化并设置参数

```
self.camera = [[WHCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480
                                             delegate:self
                                captureDevicePosition:AVCaptureDevicePositionFront
                                            inSubView:self.view
                                             depthTag:YES
                                          adaptCamera:YES
                                             portrait:YES
                                          fillPreView:YES];
```
4、开启摄像头

```
[self.camera startCamera];
```
5、视频流回调函数

```
#pragma mark - WHCameraDelegate

- (void)whCamera:(WHCamera *)whCamera didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"%s",__func__);
}

- (void)whCamera:(WHCamera *)whCamera didOutputSyncedSampleBufferData:(AVCaptureSynchronizedSampleBufferData *)syncedSampleBufferData syncedDepthBufferData:(AVCaptureSynchronizedDepthData *)syncedDepthBufferData
API_AVAILABLE(ios(11.0)){
    NSLog(@"%s",__func__);
}

```
6、摄像头停止运行

```
[self.camera stopCamera];
```
7、最后释放，避免内存泄漏

```
[self.camera releaseCamera];
```
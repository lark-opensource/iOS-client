//
//  BDCTTakePhotoBaseViewController.h
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/3/15.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN


@interface BDCTTakePhotoBaseViewController : UIViewController


@property (nonatomic, copy) NSString *type;

@property (strong, nonatomic) AVCaptureSession *session;

// 照片输出流对象
@property (strong, nonatomic) AVCaptureStillImageOutput *captureOutput;

// 代表了输入设备,例如摄像头与麦克风
@property (strong, nonatomic) AVCaptureDevice *captureDevice;
// AVCaptureDeviceInput对象是输入流(摄像头或者麦克风),一个设备可能可以同时提供视频和音频的捕捉。我们可以分别用AVCaptureDeviceInput来代表视频输入和音频输入
@property (strong, nonatomic) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
// 预览图层，来显示照相机拍摄到的画面
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;

@property (nonatomic, strong) UIView *focusView;

- (void)loadCaptureSession;

- (void)initSubViews;

- (void)focusAtPoint:(CGPoint)point;

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;
@end

NS_ASSUME_NONNULL_END

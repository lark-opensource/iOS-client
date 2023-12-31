//
//  LVDCameraServiceInterface.h
//  LarkVideoDirector
//
//  Created by Saafo on 2023/7/11.
//

#ifndef LVDCameraServiceInterface_h
#define LVDCameraServiceInterface_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// 这个文件存在是因为 LVD 在 Xcode 14 中 import CameraClient 库，会报
// Include of non-modular header inside framework module 的错误
// 就需要 使用 LVD 的所有库都打开 CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES 设置选项
// Xcode 15 貌似没有这个问题，就可以把当前文件的内容迁移到 *.swift 中
// 并且把 LVDCameraService.h/m 迁移到 *.swift 中，并删除 LVD.h

@protocol LVDCameraControllerDelegate

- (void)cameraTakePhoto:(UIImage *)image from:(nullable NSString *)lens controller:(UIViewController *)vc;
- (void)cameraTakeVideo:(NSURL *)videoURL controller:(UIViewController *)vc;
- (void)cameraDidDismissFrom:(UIViewController *)vc;
@end

@protocol LVDVideoEditorControllerDelegate

- (void)editorTakeVideo:(NSURL *)videoURL controller:(UIViewController *)vc;

@end

typedef NS_ENUM(NSInteger, LVDCameraType) {
    LVDCameraTypeSupportPhotoAndVideo,
    LVDCameraTypeOnlySupportPhoto,
    LVDCameraTypeOnlySupportVideo,
};

@protocol LVDCameraServiceProtocol

/// 是否可用
///
/// 有 CKNLE 模块和实现时为 true，否则为 false
+ (BOOL)available;

/// 设置 iPhone 是否支持 1080p 相机, iPhone 默认支持，iPad 默认强制支持
+ (void)setCameraSupport1080:(BOOL)support;

/// 当前是否支持 1080P 拍摄
+ (BOOL)cameraSupport1080;

/// CK 相机
+ (nonnull UIViewController *)cameraControllerWith:(id<LVDCameraControllerDelegate>)delegate
                                        cameraType:(LVDCameraType)type;

/// CK 相机
///
/// - Parameters:
///   - maxDuration: 小于等于 1 时不生效
+ (nonnull UIViewController *)cameraControllerWith:(id<LVDCameraControllerDelegate>)delegate
                                        cameraType:(LVDCameraType)type
                                    cameraPosition:(AVCaptureDevicePosition)position
                                  videoMaxDuration:(double)maxDuration;
/// NLE 编辑器
+ (nonnull UIViewController *)videoEditorControllerWith:(id<LVDVideoEditorControllerDelegate>)delegate
                                                 assets:(NSArray<AVAsset *>*)assets
                                                   from:(UIViewController*)vc;

@end

#endif /* LVDCameraServiceInterface_h */

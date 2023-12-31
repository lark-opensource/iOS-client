//
//  BDPPluginImageCustomImpl.m
//  Pods
//
//  Created by zhangkun on 18/07/2018.
//

#import "BDPPluginImageCustomImpl.h"
#import <OPFoundation/TMAWebkitResourceManager.h>
#import <OPPluginBiz/OPPluginBiz-Swift.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <OPFoundation/BDPChooseImagePluginModel.h>
#import <OPFoundation/BDPMediaPluginDelegate.h>
#import <TTMicroApp/BDPNavigationController.h>
#import <OPFoundation/BDPRouteMediator.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPFoundation/EEFeatureGating.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/BDPUtils.h>

@interface BDPPluginImageCustomImpl() <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
/// BOOL参数表示用户是否选择的是原始图像
@property (nonatomic, copy) void (^resultCallback)(NSArray<UIImage *> *, BOOL, BDPImageAuthResult);
@property (nonatomic, strong) BDPNavigationController *navController;
@property (nonatomic, assign) BOOL disablePopGesture;

@end

@implementation BDPPluginImageCustomImpl

#pragma mark - BDPImagePluginDelegate

+ (instancetype)sharedPlugin
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (void)bdp_chooseImageWithModel:(BDPChooseImagePluginModel * _Nonnull)model fromController:(UIViewController * _Nullable)fromController completion:(void (^ _Nonnull)(NSArray<UIImage *> * _Nullable images, BOOL isOriginal, BDPImageAuthResult authResult))completion {
    self.resultCallback = completion;
    BOOL allowAlbumMode = model.bdpSourceType & BDPImageSourceTypeAlbum;
    BOOL allowCameraMode = model.bdpSourceType & BDPImageSourceTypeCamera;
    UIViewController *topVC = [OPNavigatorHelper topMostAppControllerWithWindow:fromController.view.window];

    BOOL original = model.bdpSizeType & BDPImageSizeTypeOriginal;
    BOOL compressed = model.bdpSizeType & BDPImageSizeTypeCompressed;
    BOOL useOpcamera = [EEFeatureGating boolValueForKey:@"openplatform.api.choose_image_use_opcamera"];
    NSString *confirmBtnText = model.confirmBtnText;
    BDPLogInfo(@"bdp_chooseImageWithModel, count=%@, bdpSizeType=%@, bdpSourceType=%@, useOpcamera=%@", @(model.count), @(model.bdpSizeType), @(model.bdpSourceType), @(useOpcamera));

    if (useOpcamera){
        [EMAImagePicker pickImageWithMaxCount:model.count
                               allowAlbumMode:allowAlbumMode
                              allowCameraMode:allowCameraMode
                             isOriginalHidden:!(original && compressed)
                                   isOriginal:(original && !compressed) ///只有用户指定是原图的时候，才初始化选择原图，否则默认是压缩图
                                 singleSelect:NO
                                 cameraDevice:model.cameraDevice
                                           in:topVC
                               resultCallback:^(NSArray<UIImage *> * _Nullable images, BOOL isOriginal, BDPImageAuthResult authResult) {
            BDPLogInfo(@"pickImage result %@", BDPParamStr(@(images.count), @(isOriginal)));
            if (images && images.count) {
                [self ttImagePickerResult:images isOriginal:isOriginal authType:authResult];
            } else {
                [self ttImagePickerResult:nil isOriginal:isOriginal authType:authResult];
            }
        }];
    }else {
        BOOL isSaveToAlbum = NO;
        if (!BDPIsEmptyString(model.isSaveToAlbum) && [model.isSaveToAlbum isEqualToString:@"1"]){
            isSaveToAlbum = YES;
        }

        [EMAImagePicker pickImageV2WithMaxCount:model.count
                               allowAlbumMode:allowAlbumMode
                              allowCameraMode:allowCameraMode
                             isOriginalHidden:!(original && compressed)
                                   isOriginal:(original && !compressed) ///只有用户指定是原图的时候，才初始化选择原图，否则默认是压缩图
                                 singleSelect:NO
                                isSaveToAlbum:isSaveToAlbum
                                 cameraDevice:model.cameraDevice
                                 confirmBtnText:confirmBtnText
                                           in:topVC
                               resultCallback:^(NSArray<UIImage *> * _Nullable images, BOOL isOriginal, BDPImageAuthResult authResult) {
            BDPLogInfo(@"pickImageV2 result %@", BDPParamStr(@(images.count), @(isOriginal)));
            if (images && images.count) {
                [self ttImagePickerResult:images isOriginal:isOriginal authType:authResult];
            } else {
                [self ttImagePickerResult:nil isOriginal:isOriginal authType:authResult];
            }
        }];
    }
    
}

/// 选择器取消选择的回调
- (void)ttImagePickerResult:(NSArray<UIImage *> * _Nullable)images isOriginal:(BOOL)isOriginal authType: (BDPImageAuthResult)authResult
{
    [self ablePopGestureAction];
    if (self.resultCallback) {
        self.resultCallback(images, isOriginal, authResult);
        self.resultCallback = nil;
    }
}

#pragma mark - Private

- (void)disablePopGestureAction:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[BDPNavigationController class]]) {
        self.navController = (BDPNavigationController *)viewController;
        self.disablePopGesture = YES;
        self.navController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)ablePopGestureAction {
    if (self.disablePopGesture) {
        self.disablePopGesture = NO;
        self.navController.interactivePopGestureRecognizer.enabled = YES;
        self.navController = nil;
    }
}
@end

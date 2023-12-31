//
//  BytedCertCamera.m
//  BytedCert
//
//  Created by LiuChundian on 2019/5/29.
//

#import <Accelerate/Accelerate.h>
#import <GLKit/GLKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "BDCTImageManager.h"
#import "BDCTAPIService.h"
#import "BDCTTakePhotoViewController.h"
#import "BDCTLocalization.h"
#import "BytedCertInterface.h"
#import "BDCTEventTracker.h"
#import "BDCTLog.h"
#import "NSData+BDCTAdditions.h"
#import "UIImage+BDCTAdditions.h"
#import "UIViewController+BDCTAdditions.h"
#import "BDCTAdditions.h"
#import "BDCTFlow.h"

static NSString *const kBytedCertImageSelectedFromAlbum = @"from_album";
static NSString *const kBytedCertImageSelectedFromCamera = @"take_photo";

static NSData *byted_cert_compress_image_for_upload(UIImage *image, CGFloat compressRatio) {
    if (!image) {
        return nil;
    }
    UIImage *resultImage = image;
    CGFloat sizeRatio = MAX(MAX(resultImage.size.width, resultImage.size.height) / 1280, MIN(resultImage.size.width, resultImage.size.height) / 720);
    if (sizeRatio > 1) {
        CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width / sqrtf(sizeRatio)),
                                 (NSUInteger)(resultImage.size.height / sqrtf(sizeRatio)));
        UIGraphicsBeginImageContext(size);
        [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return UIImageJPEGRepresentation(resultImage, compressRatio > 0 ? compressRatio : 0.85);
}


@interface BDCTImageManager () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) BDCTEventTracker *eventTracker;

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSData *> *typeToImageDic;

@property (nonatomic, assign) int maxSide;

@property (nonatomic, assign) CGFloat compressRatioWeb; // web压缩比例，0-1，服务端返回0-100
@property (nonatomic, assign) CGFloat compressRatioNet; // 接口压缩比例，0-1，服务端返回0-100

// 用于记录相册选择照片时的起始时间
@property (nonatomic, strong) NSDate *imageSelectStartTime;

@property (nonatomic, copy) void (^completionBlock)(NSDictionary *_Nullable result);

@end


@implementation BDCTImageManager

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _typeToImageDic = [NSMutableDictionary dictionary];
    _compressRatioNet = -1;
    _compressRatioWeb = -1;
    _maxSide = 800;
    return self;
}

- (BDCTEventTracker *)eventTracker {
    if (!_eventTracker) {
        _eventTracker = self.flow.eventTracker ?: [BDCTEventTracker new];
    }
    return _eventTracker;
}

- (void)selectImageWithParams:(NSDictionary *)args completion:(void (^)(NSDictionary *))callback {
    if (args == nil || args == (NSDictionary *)[NSNull null] || args[@"type"] == nil || args[@"max_side"] == nil) {
        BDCTLogInfo(@"args: %@\n", args);
        !callback ?: callback(@{@"status_code" : @(BytedCertErrorArgs)});
        return;
    }
    self.type = args[@"type"];
    self.maxSide = [args[@"max_side"] intValue];
    NSNumber *compressWebNum = args[@"compress_ratio_web_ios"];
    if (compressWebNum && [compressWebNum isKindOfClass:[NSNumber class]]) {
        self.compressRatioWeb = [compressWebNum integerValue] / 100.0f;
    }
    NSNumber *compressNetNum = args[@"compress_ratio_net_ios"];
    if (compressNetNum && [compressNetNum isKindOfClass:[NSNumber class]]) {
        self.compressRatioNet = [compressNetNum integerValue] / 100.0f;
    }
    BDCTLogInfo(@"invokeTakePhotoAlert #type: %@, #maxSide: %d\n", self.type, self.maxSide);
    self.completionBlock = callback;
    if ([args[@"is_only_camera"] boolValue]) {
        [self takePhotoFromCamera];
        return;
    }
    if ([args[@"is_only_album"] boolValue]) {
        [self selectedImageFromAlbum];
        return;
    }

    UIAlertController *alertController = nil;
    if ([[UIDevice currentDevice].model hasPrefix:@"iPad"]) {
        alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    } else {
        alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    }
    // 相机选项
    [alertController addAction:[UIAlertAction actionWithTitle:BytedCertLocalizedString(@"拍照") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                         [self takePhotoFromCamera];
                     }]];
    // 相册选项
    [alertController addAction:[UIAlertAction actionWithTitle:BytedCertLocalizedString(@"从相册选择") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                         [self selectedImageFromAlbum];
                     }]];
    // 取消按钮
    [alertController addAction:[UIAlertAction actionWithTitle:BytedCertLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
                         [self callbackWithCancel];
                     }]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIViewController bdct_topViewController] presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)selectedImageFromAlbum {
    self.imageSelectStartTime = [NSDate date];
    [UIApplication bdct_requestAlbumPermissionWithSuccessBlock:^{
        if ([[BytedCertInterface sharedInstance].bytedCertCameraDelegate respondsToSelector:@selector(didSelectPhotolibrary)]) {
            [[BytedCertInterface sharedInstance].bytedCertCameraDelegate performSelector:@selector(didSelectPhotolibrary)];
            [[BytedCertInterface sharedInstance] setBytedCertCameraCallback:^(UIImage *_Nonnull image) {
                if (!image) {
                    [self callbackWithCancel];
                    return;
                }
                NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
                [self cacheImageForUpdate:image metaData:imageData.bdct_imageMetaData];
                [self callbackWithSelectedImage:image from:kBytedCertImageSelectedFromAlbum];
            }];
        } else {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = NO; // 因为下面用的是 UIImagePickerControllerEditedImage，所以这边要开启 Edit 的选项，否则返回 nil
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [[UIViewController bdct_topViewController] presentViewController:picker animated:YES completion:nil];
        }
    } failBlock:^{
        self.completionBlock(@{@"status_code" : @(BytedCertErrorCameraPermission)});
    }];
    [self.eventTracker trackCardPhotoUpdateAlertClick:kBytedCertImageSelectedFromAlbum];
}

- (void)takePhotoFromCamera {
    self.imageSelectStartTime = [NSDate date];

    // 设置数据源为相机
    [AVCaptureDevice bdct_requestAccessForCameraWithSuccessBlock:^{
        [BDCTTakePhotoViewController takePhotoForType:self.type completion:^(UIImage *cropedImage, UIImage *resultPhoto, NSDictionary *metaData) {
            if (!cropedImage || !resultPhoto) {
                [self callbackWithCancel];
                return;
            }
            [self cacheImageForUpdate:resultPhoto metaData:metaData];
            [self callbackWithSelectedImage:cropedImage from:kBytedCertImageSelectedFromCamera];
        }];
    } failBlock:^{
        self.completionBlock(@{@"status_code" : @(BytedCertErrorCameraPermission)});
    }];
    [self.eventTracker trackCardPhotoUpdateAlertClick:kBytedCertImageSelectedFromCamera];
}

- (NSData *)getImageByType:(NSString *)type {
    return type ? _typeToImageDic[type] : nil;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    BDCTLogInfo(@"imagePickerController\n");
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [self cacheImageForUpdate:image metaData:imageData.bdct_imageMetaData];
    [self callbackWithSelectedImage:image from:kBytedCertImageSelectedFromAlbum];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    BDCTLogInfo(@"imagePickerControllerDidCancel\n");
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self callbackWithCancel];
}

- (void)cacheImageForUpdate:(UIImage *)image metaData:(NSDictionary *)metaData {
    NSData *imageData = byted_cert_compress_image_for_upload(image, self.compressRatioNet);
    if (imageData && metaData) {
        imageData = [NSData bdct_saveImageWithImageData:imageData properties:metaData];
    }
    if (_type) {
        [_typeToImageDic setValue:imageData forKey:_type];
    }
}

- (void)callbackWithSelectedImage:(UIImage *)selectedImage from:(NSString *)from {
    // 处理图片用于h5展示
    UIImage *webDisplayImage = [selectedImage bdct_resizeWithMaxSide:self.maxSide];
    CGFloat compressWeb = 0.03f;
    if (self.compressRatioWeb >= 0) {
        compressWeb = self.compressRatioWeb;
    }
    NSString *imageBase64Data = [UIImageJPEGRepresentation(webDisplayImage, compressWeb) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSDictionary *params = @{
        @"status_code" : @(0),
        @"data" : @{
            @"image_b64" : [NSString stringWithFormat:@"data:image/jpeg;base64,%@", imageBase64Data],
            @"stay_inner_time" : @((int)fabs([self.imageSelectStartTime timeIntervalSinceNow])),
            @"upload_type" : from,
            @"camera_valid" : @([AVCaptureDevice bdct_hasCameraPermission])
        }
    };
    [self.eventTracker trackIdCardPhotoUploadSelectFinish];
    self.completionBlock(params);
}

- (void)callbackWithCancel {
    NSDictionary *data = @{@"status_code" : @(BytedCertErrorAlertCancel),
                           @"data" : @{@"camera_valid" : @([AVCaptureDevice bdct_hasCameraPermission])}};
    self.completionBlock(data);
    [self.eventTracker trackCardPhotoUpdateAlertClick:@"upload_cancel"];
}

@end

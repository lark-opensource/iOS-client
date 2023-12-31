//
//  BDCTManualReviewViewController.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/3/15.
//

#import "BDCTTakeOCRPhotoViewController.h"
#import "UIViewController+BDCTAdditions.h"
#import "UIImage+BDCTAdditions.h"
#import "NSData+BDCTAdditions.h"
#import "BDCTImageManager.h"
#import "BDCTFlow.h"
#import "BDCTAPIService.h"
#import "UIApplication+BDCTAdditions.h"
#import "BytedCertManager+Private.h"
#import "BDCTLocalization.h"
#import "NSBundle+BDCTAdditions.h"
#import "BDCTEventTracker.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <Masonry/Masonry.h>


@interface BDCTTakeOCRPhotoViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) CAShapeLayer *maskLayer;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIImageView *cropFrameImageView;
@property (nonatomic, strong) UIImageView *cropInnerImageView;
@property (nonatomic, strong) UIButton *photoButton;
@property (nonatomic, strong) UILabel *bottomTipLabel;
@property (nonatomic, strong) UILabel *sideTipLabel;
@property (nonatomic, strong) UIButton *selectAlbumPhotoButton;

@property (nonatomic, assign) int maxSide;
@property (nonatomic, assign) CGFloat compressRatioWeb; // web压缩比例，0-1，服务端返回0-100
@property (nonatomic, assign) CGFloat compressRatioNet;

@end

#define pointRotatedAroundAnchorPoint(point, anchorPoint, angle) CGPointMake((point.x - anchorPoint.x) * cos(angle) - (point.y - anchorPoint.y) * sin(angle) + anchorPoint.x, (point.x - anchorPoint.x) * sin(angle) + (point.y - anchorPoint.y) * cos(angle) + anchorPoint.y)


@implementation BDCTTakeOCRPhotoViewController

+ (instancetype)viewControllerWithParams:(NSDictionary *_Nonnull)params completion:(nullable void (^)(NSDictionary *_Nullable ocrResult))completion {
    if (params == nil || params == (NSDictionary *)[NSNull null] || params[@"type"] == nil) {
        return nil;
    }
    BDCTTakeOCRPhotoViewController *cameraVC = [BDCTTakeOCRPhotoViewController new];
    cameraVC.type = [params btd_stringValueForKey:@"type"];
    cameraVC.maxSide = 800;
    cameraVC.completionBlock = completion;
    cameraVC.modalPresentationStyle = UIModalPresentationOverFullScreen;

    return cameraVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self layoutViews];
}

- (void)layoutViews {
    [self.flow.eventTracker trackWithEvent:@"manual_detection_camera_show" params:nil];
    self.preview.frame = self.view.bounds;
    [self.view.layer addSublayer:self.maskLayer];
    self.backButton.frame = CGRectMake(20, 60, 8, 16);

    [self.cropFrameImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_offset(112);
        make.left.mas_equalTo(self.view).offset(48);
        make.right.mas_equalTo(self.view).offset(-48);
        make.bottom.mas_equalTo(self.view).offset((-240));
    }];

    [self.cropInnerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.cropFrameImageView).offset(-50);
        make.bottom.mas_equalTo(self.cropFrameImageView).offset(-50);
        make.width.mas_equalTo(129);
        make.width.mas_equalTo(140);
    }];

    [self.sideTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.cropFrameImageView.mas_left).mas_offset(self.sideTipLabel.bounds.size.height * 1.5);
        make.centerY.mas_equalTo(self.cropFrameImageView.mas_centerY);
    }];
    self.sideTipLabel.transform = CGAffineTransformMakeRotation(M_PI / 2);

    [self.bottomTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.cropFrameImageView.mas_bottom).mas_offset(20);
        make.width.mas_equalTo(self.cropFrameImageView.mas_width);
        make.left.mas_equalTo(self.cropFrameImageView.mas_left);
    }];

    [self.selectAlbumPhotoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(25);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-30);
        } else {
            make.bottom.equalTo(self.view).offset(-30);
        }
    }];

    [self.photoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.selectAlbumPhotoButton.mas_top).offset(-30);
        make.width.mas_equalTo(340);
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.height.mas_equalTo(44);
    }];
}


#pragma mark - View控件


- (CAShapeLayer *)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [CAShapeLayer layer];
        _maskLayer.path = [self getMaskPath].CGPath;
        _maskLayer.fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.72].CGColor;
    }
    return _maskLayer;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton setImage:[UIImage imageNamed:@"ocr_return_button" inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_backButton];
    }

    return _backButton;
}

- (UIImageView *)cropFrameImageView {
    if (!_cropFrameImageView) {
        UIImage *frameImage1 = [UIImage imageNamed:[NSString stringWithFormat:@"%@_ocr_cropFrame", self.type] inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil];
        UIImage *frameImage2 = [UIImage imageNamed:[NSString stringWithFormat:@"%@_ocr_cropCorner", self.type] inBundle:[NSBundle bdct_bundle] compatibleWithTraitCollection:nil];
        UIImage *resultImage = [self addImage:frameImage1 withImage:frameImage2];
        _cropFrameImageView = [UIImageView new];
        _cropFrameImageView.image = resultImage;
        [self.view addSubview:_cropFrameImageView];
    }
    return _cropFrameImageView;
}

- (UIImageView *)cropInnerImageView {
    if (!_cropInnerImageView) {
        NSString *imageName = [NSString stringWithFormat:@"%@_ocr_cropInner", self.type];
        UIImage *image = [UIImage bdct_imageWithName:imageName];
        _cropInnerImageView = [UIImageView new];
        _cropInnerImageView.image = image;
        [_cropInnerImageView sizeToFit];
        [self.cropFrameImageView addSubview:_cropInnerImageView];
    }
    return _cropInnerImageView;
}

- (UILabel *)sideTipLabel {
    if (!_sideTipLabel) {
        _sideTipLabel = [UILabel new];
        _sideTipLabel.text = @"请拍摄身份证人面像，并尝试对齐边缘";
        _sideTipLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _sideTipLabel.textColor = [UIColor btd_colorWithHexString:@"#FFFFFF" alpha:0.9];
        _sideTipLabel.textAlignment = NSTextAlignmentCenter;
        [_sideTipLabel sizeToFit];
        [self.cropFrameImageView addSubview:_sideTipLabel];
    }
    return _sideTipLabel;
}

- (UILabel *)bottomTipLabel {
    if (!_bottomTipLabel) {
        _bottomTipLabel = [UILabel new];
        _bottomTipLabel.numberOfLines = 0;
        _bottomTipLabel.text = @"请将身份证正面照正对摄像头，并对齐屏幕中视频框的位置，确认后点击下方拍摄按钮";
        _bottomTipLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
        _bottomTipLabel.textColor = [UIColor btd_colorWithHexString:@"#FFFFFF" alpha:0.75];
        [_bottomTipLabel sizeToFit];
        [self.view addSubview:_bottomTipLabel];
    }
    return _bottomTipLabel;
}

- (UIButton *)photoButton {
    if (!_photoButton) {
        _photoButton = [UIButton new];
        _photoButton.backgroundColor = [UIColor btd_colorWithHexString:@"#FE2C55"];
        _photoButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
        _photoButton.layer.cornerRadius = 4;
        [_photoButton setTitle:@"开始拍摄" forState:UIControlStateNormal];
        [_photoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_photoButton];
    }
    return _photoButton;
}

- (UIButton *)selectAlbumPhotoButton {
    if (!_selectAlbumPhotoButton) {
        _selectAlbumPhotoButton = [[UIButton alloc] init];
        _selectAlbumPhotoButton.backgroundColor = [UIColor clearColor];
        [_selectAlbumPhotoButton setAttributedTitle:[self createAttributedText] forState:UIControlStateNormal];
        [_selectAlbumPhotoButton addTarget:self action:@selector(selectPhotoFromAlbum) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_selectAlbumPhotoButton];
    }
    return _selectAlbumPhotoButton;
}

#pragma mark - 控件actions

- (void)cancel {
    [self finishTakeOCRWithDisplayImage:nil ocrResult:@{@"status_code" : @(BytedCertErrorClickCancel)}];
}

- (void)quite {
    [self finishTakeOCRWithDisplayImage:nil ocrResult:@{@"status_code" : @(BytedCertErrorAlertCancel)}];
}

- (void)takePhoto {
    AVCaptureConnection *stillImageConnection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];

    [self.captureOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (CMSampleBufferIsValid(imageDataSampleBuffer)) {
            self.photoButton.hidden = YES;
            // 这里导出的图片imageOrientation总是为UIImageOrientationRight
            NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            [self handleSelectedImage:[UIImage imageWithData:jpegData] metaData:jpegData.bdct_imageMetaData from:@"camera"];
        }
    }];
}

- (void)selectPhotoFromAlbum {
    [UIApplication bdct_requestAlbumPermissionWithSuccessBlock:^{
        if ([[BytedCertInterface sharedInstance].bytedCertCameraDelegate respondsToSelector:@selector(didSelectPhotolibrary)]) {
            [[BytedCertInterface sharedInstance].bytedCertCameraDelegate performSelector:@selector(didSelectPhotolibrary)];
            [[BytedCertInterface sharedInstance] setBytedCertCameraCallback:^(UIImage *_Nonnull image) {
                if (!image) {
                    return;
                }
                NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
                [self handleSelectedImage:image metaData:imageData.bdct_imageMetaData from:@"photo"];
            }];
        } else {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = NO; // 因为下面用的是 UIImagePickerControllerEditedImage，所以这边要开启 Edit 的选项，否则返回 nil
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [[UIViewController bdct_topViewController] presentViewController:picker animated:YES completion:nil];
        }
    } failBlock:^{

    }];
}

- (void)handleSelectedImage:(UIImage *)capturedImage metaData:(NSDictionary *)metaData from:(NSString *)from {
    if (!capturedImage || !metaData) {
        [self showAlertWithTitle:@"获取图片错误" message:nil];
        return;
    }
    UIImage *cropedImage = nil;
    if ([from isEqualToString:@"camera"]) {
        cropedImage = capturedImage;
        if (self.cropFrameImageView) {
            cropedImage = [self cropImage:capturedImage];
            cropedImage = [cropedImage bdct_transforCapturedImageWithMaxResoulution:cropedImage.size.height isFrontCamera:(self.captureDevice.position == AVCaptureDevicePositionFront)];
        }
        NSData *cropedImageData = nil;
        if (UIImagePNGRepresentation(cropedImage) == nil) {
            cropedImageData = UIImageJPEGRepresentation(cropedImage, 1);
        } else {
            cropedImageData = UIImagePNGRepresentation(cropedImage);
        }
        metaData = cropedImageData.bdct_imageMetaData;
        capturedImage = [UIImage imageWithCGImage:[cropedImage CGImage]];
    }
    NSData *imageData = [self compressImage:capturedImage metaData:metaData];
    NSString *imageName = [NSString stringWithFormat:@"%@_image", self.type];
    BDCTShowLoading;
    __block BOOL isCompleted = NO;
    @weakify(self);
    void (^callback)(NSDictionary *_Nullable, BytedCertError *_Nullable) = ^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        @strongify(self);
        if (isCompleted)
            return;
        isCompleted = YES;
        BDCTDismissLoading;
        if (error) {
            [self showAlertWithTitle:nil message:[jsonObj btd_stringValueForKey:@"message"] ?: @"发生未知错误"];
        } else {
            NSDictionary *ocrResult = [jsonObj btd_dictionaryValueForKey:@"data"];
            if ([from isEqualToString:@"photo"]) {
                NSArray *imageCorners = [ocrResult btd_arrayValueForKey:[NSString stringWithFormat:@"%@_image_card_corners", self.type]];
                UIImage *ocrImage = [UIImage imageWithData:imageData];
                UIImage *rotatedImage = [self rotateAndCropImage:ocrImage withRectCorners:imageCorners];
                [self finishTakeOCRWithDisplayImage:rotatedImage ocrResult:ocrResult];
            } else {
                [self finishTakeOCRWithDisplayImage:cropedImage ocrResult:ocrResult];
            }
        }
        NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
        trackParams[@"result"] = error ? @"fail" : @"success";
        trackParams[@"submit_type"] = from;
        trackParams[@"error_code"] = @(error.errorCode);
        trackParams[@"fail_info"] = error.errorMessage;
        [self.flow.eventTracker trackWithEvent:@"manual_detection_photo_result" params:trackParams.copy];
    };
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BytedCertError *error = [[BytedCertError alloc] initWithType:(BytedCertErrorServer)];
        callback(nil, error);
    });
    [self.flow.apiService bytedOCRWithImageDataArray:@[ imageData ] imageNameArray:@[ imageName ] callback:^(NSDictionary *_Nullable jsonObj, BytedCertError *_Nullable error) {
        callback(jsonObj, error);
    }];
}

- (UIImage *)cropImage:(UIImage *)image {
    UIImage *cropedImage = [image bdct_cropToRect:[self cropRectForFrame:self.cropFrameImageView.frame image:image]];

    return cropedImage;
}

- (CGRect)cropRectForFrame:(CGRect)frame image:(UIImage *)image {
    CGFloat widthScale = self.view.bounds.size.width / image.size.width;
    CGFloat heightScale = self.view.bounds.size.height / image.size.height;
    float x, y, w, h, offset;
    if (widthScale < heightScale) {
        offset = (self.view.bounds.size.height - (image.size.height * widthScale)) / 2;
        x = frame.origin.x / widthScale;
        y = (frame.origin.y - offset) / widthScale;
        w = frame.size.width / widthScale;
        h = frame.size.height / widthScale;
    } else {
        offset = (self.view.bounds.size.width - (image.size.width * heightScale)) / 2;
        x = (frame.origin.x - offset) / heightScale;
        y = frame.origin.y / heightScale;
        w = frame.size.width / heightScale;
        h = frame.size.height / heightScale;
    }
    return CGRectMake(x, y, w, h);
}

- (UIImage *)rotateAndCropImage:(UIImage *)image withRectCorners:(NSArray<NSNumber *> *)corners {
    if (corners.count != 8)
        return image;
    CGPoint a, b, c, d, center;
    a.x = corners[0].doubleValue;
    a.y = corners[1].doubleValue;
    b.x = corners[2].doubleValue;
    b.y = corners[3].doubleValue;
    c.x = corners[4].doubleValue;
    c.y = corners[5].doubleValue;
    d.x = corners[6].doubleValue;
    d.y = corners[7].doubleValue;
    double radians = 0;
    double xGab = fabs(a.x - b.x);
    double yGab = fabs(a.y - b.y);
    double width = sqrt(pow(xGab, 2) + pow(yGab, 2));
    double height = sqrt(pow(fabs(b.x - c.x), 2) + pow(fabs(b.y - c.y), 2));
    double cosValue = xGab / width;

    double k1 = (a.y - c.y) / (a.x - c.x);
    double k2 = (b.y - d.y) / (b.x - d.x);
    double s1 = a.y - k1 * a.x;
    double s2 = b.y - k2 * b.x;
    center.x = (s2 - s1) / (k1 - k2);
    center.y = k1 * center.x + s1;

    if (a.x <= b.x) {
        radians = a.y < b.y ? -acos(cosValue) : acos(cosValue);
    } else if (a.x > b.x) {
        radians = a.y < b.y ? -(M_PI - acos(cosValue)) : (M_PI - acos(cosValue));
    }

    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    CGRect sizeRect = (CGRect){.size = image.size};
    CGRect destRect = CGRectApplyAffineTransform(sizeRect, t);
    CGSize destinationSize = destRect.size;

    UIGraphicsBeginImageContext(destinationSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, center.x, center.y);
    CGContextRotateCTM(context, radians);
    [image drawInRect:CGRectMake(-center.x, -center.y, image.size.width, image.size.height)];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGPoint rotatedA = pointRotatedAroundAnchorPoint(a, center, radians);
    CGRect myImageRect = CGRectMake(rotatedA.x - 20, rotatedA.y - 20, width + 80, height + 80);
    CGImageRef subImageRef = CGImageCreateWithImageInRect(newImage.CGImage, myImageRect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    UIGraphicsBeginImageContext(smallBounds.size);
    context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage *smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();

    return smallImage;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [self handleSelectedImage:image metaData:imageData.bdct_imageMetaData from:@"photo"];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIBezierPath *)getMaskPath {
    CGRect rect = self.view.bounds;
    CGRect exceptRect;
    exceptRect.origin.x = 48;
    exceptRect.origin.y = 112;
    exceptRect.size.width = rect.size.width - 96;
    exceptRect.size.height = rect.size.height - 112 - 240;
    if (!CGRectContainsRect(rect, exceptRect)) {
        return nil;
    } else if (CGRectEqualToRect(rect, CGRectZero)) {
        return nil;
    }

    CGFloat boundsInitX = CGRectGetMinX(rect);
    CGFloat boundsInitY = CGRectGetMinY(rect);
    CGFloat boundsWidth = CGRectGetWidth(rect);
    CGFloat boundsHeight = CGRectGetHeight(rect);

    CGFloat minX = CGRectGetMinX(exceptRect);
    CGFloat maxX = CGRectGetMaxX(exceptRect);
    CGFloat minY = CGRectGetMinY(exceptRect);
    CGFloat maxY = CGRectGetMaxY(exceptRect);
    CGFloat width = CGRectGetWidth(exceptRect);

    /** 添加路径*/
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(boundsInitX, boundsInitY, minX, boundsHeight)];
    [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(minX, boundsInitY, width, minY)]];
    [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(maxX, boundsInitY, boundsWidth - maxX, boundsHeight)]];
    [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(minX, maxY, width, boundsHeight - maxY)]];

    return path;
}

- (NSMutableAttributedString *)createAttributedText {
    //普通字体的大小颜色
    NSDictionary *normalAtt = @{NSFontAttributeName : [UIFont systemFontOfSize:13], NSForegroundColorAttributeName : [UIColor btd_colorWithHexString:@"#FFFFFF" alpha:0.75]};

    //可点击字体的大小颜色
    NSDictionary *specAtt = @{NSFontAttributeName : [UIFont systemFontOfSize:13], NSForegroundColorAttributeName : [UIColor btd_colorWithHexString:@"#FE2C55"]};

    //生成默认的字符串
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:@"身份证没在身边？试试" attributes:normalAtt];

    //添加特殊部分在尾部
    NSMutableAttributedString *click = [[NSMutableAttributedString alloc] initWithString:@"相册上传" attributes:specAtt];
    [attStr appendAttributedString:click];

    //设置居中
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    [attStr addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, attStr.length)];

    return attStr;
}

- (UIImage *)addImage:(UIImage *)image1 withImage:(UIImage *)image2 {
    if (image1 && image2) {
        UIGraphicsBeginImageContext(image1.size);
        //UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);//这样就不模糊了
        [image1 drawInRect:CGRectMake(0, 0, image1.size.width, image1.size.height)];
        [image2 drawInRect:CGRectMake(0, 0, image1.size.width, image1.size.height)];
        UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return resultImage;
    }
    return nil;
}

- (NSData *)compressImage:(UIImage *)image metaData:(NSDictionary *)metaData {
    NSData *imageData = [UIImage bdct_compressImage:image compressRatio:0];
    return imageData;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [BytedCertManager showAlertOnViewController:self title:title message:message actions:@[
        [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeCancel title:@"退出" handler:^{
            [self quite];
        }],
        [BytedCertAlertAction actionWithType:BytedCertAlertActionTypeDefault title:@"重新拍摄" handler:^{
            self.photoButton.hidden = NO;
        }]
    ]];
}

- (void)finishTakeOCRWithDisplayImage:(UIImage *)image ocrResult:(NSDictionary *)ocrResult {
    UIImage *webDisplayImage = [image bdct_resizeWithMaxSide:self.maxSide];
    CGFloat compressWeb = 0.03f;
    if (self.compressRatioWeb >= 0) {
        compressWeb = self.compressRatioWeb;
    }
    NSString *imageBase64Data = [UIImageJPEGRepresentation(webDisplayImage, compressWeb) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSMutableDictionary *mutableResult = [NSMutableDictionary dictionary];
    [mutableResult addEntriesFromDictionary:ocrResult];
    mutableResult[@"image"] = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", imageBase64Data];

    NSDictionary *callbackParams = @{
        @"status_code" : @(0),
        @"data" : mutableResult.copy
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [self bdct_dismissWithComplation:^{
            if (self.completionBlock != nil) {
                self.completionBlock(callbackParams);
                self.completionBlock = nil;
            }
        }];
    });
}

@end

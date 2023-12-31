//
//  CJPayIDCardProfileOCRViewController.m
//  Pods
//
//  Created by xutianxi on 2022/8/02.
//

#import "CJPayIDCardProfileOCRViewController.h"
#import "CJPayOCRScanWindowView.h"
#import <PhotosUI/PhotosUI.h>
#import "CJPayIDCardOCRRequest.h"
#import "CJPayIDCardOCRResponse.h"
#import "CJPayAlertUtil.h"
#import "CJPayLoadingManager.h"
#import "CJPayNavigationBarView.h"
#import "CJPayLocalCardOCRWithVisionKit.h"
#import "CJPayABTestManager.h"

@interface CJPayIDCardProfileOCRViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate,PHPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic, strong) UIView *photoIconImageView;
@property (nonatomic, assign) CFAbsoluteTime ocrAppearTime;//记录OCR扫描页展示时间
@property (nonatomic, assign) CFAbsoluteTime albumAppearTime;//记录相册拉起时间
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *safeImageView;
@property (nonatomic, strong) UILabel *titleDescLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (atomic, assign) CJPayCardOCRResult result;
@property (nonatomic, assign) BOOL isOCRPageShown;
@property (nonatomic, assign) NSUInteger requestCount;
@property (nonatomic, assign) NSUInteger callbackCount;
@property (nonatomic, assign) BOOL isFirstSampleOutput;

@end

@implementation CJPayIDCardProfileOCRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ocrType = CJPayOCRTypeIDCard;
    self.isFirstSampleOutput = YES;
    self.ocrAppearTime = [[NSDate date] timeIntervalSince1970];
    self.requestCount = 0;
    self.callbackCount = 0;
    NSString *abValue = [CJPayABTest getABTestValWithKey:CJPayABLocalOCR exposure:YES];
    NSDictionary *abDictionary = abValue.btd_jsonDictionary;
    if ([abDictionary isKindOfClass:NSDictionary.class]) {
        self.enableLocalScan = [abDictionary cj_boolValueForKey:@"enable_id_card_scan"];
        self.enableLocalPhotoUpload = [abDictionary cj_boolValueForKey:@"enable_id_card_upload"];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.isOCRPageShown) {
        self.isOCRPageShown = YES;
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_page_imp" params:@{@"ocr_source" : CJString(self.fromPage)}];
    }
}

- (void)setupUI {
    [super setupUI];
    [self.view addSubview:self.ocrScanView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.safeImageView];
    [self.view addSubview:self.titleDescLabel];
    [self.view addSubview:self.tipsLabel];
    [self.view addSubview:self.photoIconImageView];
    CJPayMasMaker(self.ocrScanView, {
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
        make.centerY.equalTo(self.view).offset(-16);
        make.height.equalTo(self.ocrScanView.mas_width).multipliedBy(CJ_OCR_SCAN_HEIGHT / CJ_OCR_SCAN_WIDTH);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.navigationBar.mas_bottom).offset(30);
        make.left.equalTo(self.view).offset(12);
        make.right.equalTo(self.view).offset(-12);
        make.height.mas_equalTo(31);
    });
    
    CJPayMasMaker(self.titleDescLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
        make.centerX.equalTo(self.view.mas_centerX).offset(18);
        make.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.safeImageView, {
        make.centerY.equalTo(self.titleDescLabel);
        make.size.mas_equalTo(CGSizeMake(16, 16));
        make.right.equalTo(self.titleDescLabel.mas_left).offset(-6);
    });
    
    CJPayMasMaker(self.tipsLabel, {
        make.left.equalTo(self.view).offset(12);
        make.right.equalTo(self.view).offset(-12);
        make.height.mas_equalTo(20);
        make.top.equalTo(self.ocrScanView.mas_bottom).offset(30);
    });
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        CJPayMasMaker(self.photoIconImageView, {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-100);
            make.top.greaterThanOrEqualTo(self.tipsLabel.mas_bottom).offset(20).priorityHigh();
        });
    } else {
        CJPayMasMaker(self.photoIconImageView, {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view.mas_bottom).offset(-16 - CJ_TabBarSafeBottomMargin - 118);
            make.top.greaterThanOrEqualTo(self.tipsLabel.mas_bottom).offset(20).priorityHigh();
        });
    }
    
    UIImageView *photoView = [UIImageView new];
    [photoView cj_setImage:@"cj_photo_library_icon"];
    [self.photoIconImageView addSubview:photoView];
    UILabel *inputLabel = [UILabel new];
    inputLabel.text = CJPayLocalizedStr(@"上传图片");
    inputLabel.font = [UIFont cj_fontOfSize:12];
    inputLabel.textColor = [UIColor whiteColor];
    [self.photoIconImageView addSubview:inputLabel];
    
    CJPayMasMaker(photoView, {
        make.width.height.mas_equalTo(24);
        make.centerY.equalTo(self.photoIconImageView);
    });
    CJPayMasMaker(inputLabel, {
        make.left.equalTo(photoView.mas_right).offset(2);
        make.centerY.equalTo(self.photoIconImageView);
    });
    CJPayMasMaker(self.photoIconImageView, {
        make.left.equalTo(photoView).offset(-43);
        make.right.equalTo(inputLabel).offset(43);
        make.top.equalTo(inputLabel).offset(-12);
        make.bottom.equalTo(inputLabel).offset(12);
    });

}

- (void)superBack {
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_page_click" params:@{
        @"button_name" : @"关闭",
        @"ocr_source" : CJString(self.fromPage)
    }];
    [super superBack];
}

- (void)switchFlashLight {
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_page_click" params:@{
        @"button_name" : @"手电筒",
        @"ocr_source" : CJString(self.fromPage)
    }];
    [super switchFlashLight];
}

- (void)p_selectPhotoToOCR {
    [self p_selectPhotoToOCRButton:YES];
}

- (void)p_selectPhotoToOCRButton:(BOOL)isFromRightTopButton {
    // 手动选择照片进行ocr识别，将扫描动画隐藏掉，禁用自动识别流程
    [self stopSession];
    CJ_DelayEnableView(self.photoIconImageView);
    [self resetAlertTimer];
    [self.ocrScanView showScanLineView:NO];
    self.recognizeEnable = NO;
    [self p_showImagePicker];
    if (isFromRightTopButton) {
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_page_click"
                          params:@{
            @"button_name" : @"上传图片",
            @"ocr_source" : CJString(self.fromPage)
        }];
    }
}

- (void)p_showImagePicker {
    self.albumAppearTime = NSDate.date.timeIntervalSince1970;
    if (@available(iOS 14.0, *)) {
        PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
        config.selectionLimit = 1;
        config.filter = [PHPickerFilter imagesFilter];
        PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:config];
        pickerViewController.delegate = self;
        pickerViewController.presentationController.delegate = self;
        [self presentViewController:pickerViewController animated:YES completion:nil];
    } else {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        imagePicker.delegate = self;
        imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
        if (@available(iOS 13.0, *)) {
            imagePicker.modalInPresentation = NO;
        }
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)p_scanWithSelectPhotoImgData:(NSData *)imgData {
    // 没有图片数据
    if (!imgData) {
        [[CJPayLoadingManager defaultService] stopLoading];
        return;
    }
    
    [self p_startRequestWithImage:imgData fromPhoto:YES];
}

- (void)p_alertPhotoOCRFail:(NSDictionary *)failDetail {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:failDetail];
    [params cj_setObject:@"2" forKey:@"card_input_type"];
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_fail_pop_imp"
                        params:[params copy]];
    @CJWeakify(self);
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"无法识别，请选择清晰的身份证人像面照片")
                                 content:nil
                          leftButtonDesc:CJPayLocalizedStr(@"重选照片")
                         rightButtonDesc:CJPayLocalizedStr(@"手动输入")
                         leftActionBlock:^{
        @CJStrongify(self);
        [self p_selectPhotoToOCRButton:NO];
        
        CJPayCardOCRResultModel *resultModel = [[CJPayCardOCRResultModel alloc] initWithResult:CJPayCardOCRResultRetry];
        resultModel.isFromUploadPhoto = YES;
        resultModel.errorCode = CJString([params cj_stringValueForKey:@"error_code"]);
        resultModel.errorMessage = CJString([params cj_stringValueForKey:@"error_message"]);
        [self trackResult:resultModel];
        
        [params cj_setObject:@"重选照片" forKey:@"button_name"];
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_fail_pop_click"
                            params:[params copy]];

    }
                         rightActioBlock:^{
        [super superBack];
        CJPayCardOCRResultModel *resultModel = [[CJPayCardOCRResultModel alloc] initWithResult:CJPayCardOCRResultUserManualInput];
        resultModel.isFromUploadPhoto = YES;
        resultModel.errorCode = CJString([params cj_stringValueForKey:@"error_code"]);
        resultModel.errorMessage = CJString([params cj_stringValueForKey:@"error_message"]);
        [self completionCallBackWithResult:resultModel];
        [params cj_setObject:@"手动输入" forKey:@"button_name"];
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_fail_pop_click"
                            params:[params copy]];
    }
                                   useVC:self];
}

- (void)alertTimeOut {
    [super alertTimeOut];
    NSString *errorMessage = CJPayLocalizedStr(@"超时识别失败");
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_fail_pop_imp"
                        params:@{@"card_input_type": @"1",
                                 @"error_message": errorMessage
                               }];
    @CJWeakify(self);
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"无法识别身份证人像面照片") content:nil leftButtonDesc:CJPayLocalizedStr(@"重试") rightButtonDesc:CJPayLocalizedStr(@"手动输入") leftActionBlock:^{
        @CJStrongify(self);
        [self.alertTimer fire];
        self.recognizeEnable = YES;
        
        CJPayCardOCRResultModel *resultModel = [[CJPayCardOCRResultModel alloc] initWithResult:CJPayCardOCRResultRetry];
        resultModel.isFromUploadPhoto = NO;
        resultModel.errorMessage = errorMessage;
        [self trackResult:resultModel];
        
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_fail_pop_click"
                            params:@{@"card_input_type": @"1",
                                     @"button_name": @"重试",
                                     @"error_message": errorMessage
                                   }];
    
    } rightActioBlock:^{
        @CJStrongify(self);
        [super superBack];
        [self completionCallBackWithResult:[[CJPayCardOCRResultModel alloc] initWithResult:CJPayCardOCRResultUserManualInput]];
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_fail_pop_click"
                            params:@{@"card_input_type": @"1",
                                     @"button_name": @"手动输入",
                                     @"error_message": errorMessage
                                   }];
    } useVC:self];
}

- (void)completionCallBackWithResult:(CJPayCardOCRResultModel *)resultModel {
    [super completionCallBackWithResult:resultModel];
    [self trackResult:resultModel];
}

- (void)trackResult:(CJPayCardOCRResultModel *)resultModel {
    CFAbsoluteTime startTime = resultModel.isFromUploadPhoto ? self.albumAppearTime : self.ocrAppearTime;
    CFAbsoluteTime durationTime = ([[NSDate date] timeIntervalSince1970] - startTime)*1000;//转成毫秒
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcardresult"
                    params:@{@"result": resultModel.result == CJPayCardOCRResultSuccess ? @"1" : @"0",
                             @"card_input_type": resultModel.isFromUploadPhoto ? @"2" : @"1",
                             @"is_from_local_ocr": resultModel.isFromLocalOCR ? @"1" : @"0",
                             @"stay_time": @((int)durationTime),
                             @"ocr_source": CJString(self.fromPage),
                             @"error_code": CJString(resultModel.errorCode),
                             @"error_message": CJString(resultModel.errorMessage),
                             @"request_count": @(self.requestCount),
                             @"callback_count": @(self.callbackCount)
                           }];
}

- (NSMutableDictionary *)p_buildBDPayCardOCRRequestParam:(NSData *)imgData {
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:self.appId forKey:@"app_id"];
    [bizParams cj_setObject:self.merchantId forKey:@"merchant_id"];
    [bizParams cj_setObject:@"ID_CARD" forKey:@"id_type"];
    
    NSString *imgBase64Str = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *imgSrcStr = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", imgBase64Str];
    [bizParams cj_setObject:[CJPaySafeUtil encryptField:imgSrcStr] forKey:@"id_photo"];
    return bizParams;
}

- (UIView *)photoIconImageView {
    if (!_photoIconImageView) {
        _photoIconImageView = [UIView new];
        _photoIconImageView.layer.cornerRadius = 21.0;
        _photoIconImageView.layer.borderWidth = 1.0;
        _photoIconImageView.layer.borderColor = [UIColor cj_ffffffWithAlpha:0.1].CGColor;
        _photoIconImageView.backgroundColor = [UIColor clearColor];
        [_photoIconImageView cj_viewAddTarget:self action:@selector(p_selectPhotoToOCR) forControlEvents:UIControlEventTouchUpInside];
    }
    return _photoIconImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:22];
        _titleLabel.textColor = [UIColor cj_ffffffWithAlpha:0.9];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = CJPayLocalizedStr(@"扫描身份证，完善持卡人信息");
    }
    return _titleLabel;
}

- (UIImageView *)safeImageView {
    if (!_safeImageView) {
        _safeImageView = [UIImageView new];
        [_safeImageView cj_setImage:@"cj_safe_white_icon"];
    }
    return _safeImageView;
}

- (UILabel *)titleDescLabel {
    if (!_titleDescLabel) {
        _titleDescLabel = [UILabel new];
        _titleDescLabel.font = [UIFont cj_fontOfSize:14];
        _titleDescLabel.textColor = [UIColor cj_ffffffWithAlpha:0.75];
        _titleDescLabel.textAlignment = NSTextAlignmentCenter;
        _titleDescLabel.text = CJPayLocalizedStr(@"身份信息扫描仅用于绑卡实名认证");
    }
    return _titleDescLabel;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.font = [UIFont cj_fontOfSize:14];
        _tipsLabel.textColor = [UIColor whiteColor];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.text = CJPayLocalizedStr(@"将身份证人像面置于此区域，并对齐扫描框边缘");
    }
    return _tipsLabel;
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    CFAbsoluteTime durationTime = (NSDate.date.timeIntervalSince1970 - self.albumAppearTime) * 1000;
    UIImage *image = [info cj_objectForKey:UIImagePickerControllerOriginalImage];
    if (![image isKindOfClass:UIImage.class]) {
        [self startSession];
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_photo_back" params:@{
            @"stay_time": @((int)durationTime),
            @"is_choose": @"0"
        }];
        return;
    }
    
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_photo_back" params:@{
        @"stay_time": @((int)durationTime),
        @"is_choose": @"1"
    }];
    @CJWeakify(self);
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self title:CJPayLocalizedStr(@"身份证读取中")];
    if (@available(iOS 14.0, *)) {
        if (self.enableLocalPhotoUpload) {
             // 仅曝光
            [self p_localScanImage:image isFromUploadPhoto:YES];
            return;
        }
    }
    
    [CJPayCardOCRUtil compressWithImage:[image copy]
                                   size:CJ_OCR_IMG_ZIP_SIZE
                        completionBlock:^(NSData * _Nonnull imageData) {
        @CJStrongify(self);
        if (self) {
            [self p_scanWithSelectPhotoImgData:imageData];
        }
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)p_localScanImage:(UIImage *)image isFromUploadPhoto:(BOOL)isFromUploadPhoto API_AVAILABLE(ios(14)){
    self.requestCount++;
    [CJ_OBJECT_WITH_PROTOCOL(CJPayLocalCardOCRWithVisionKit) recognizeIDCardWithImage:image isFromUploadPhoto:isFromUploadPhoto completion:^(CJPayCardOCRResultModel * _Nonnull resultModel) {
        self.callbackCount++;
        CFAbsoluteTime startTime = resultModel.isFromUploadPhoto ? self.albumAppearTime : self.ocrAppearTime;
        CFAbsoluteTime durationTime = (NSDate.date.timeIntervalSince1970 - startTime) * 1000;
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_single_idcardresult" params:@{
            @"result": resultModel.result == CJPayCardOCRResultSuccess ? @"1" : @"0",
            @"card_input_type": resultModel.isFromUploadPhoto ? @"2" : @"1",
            @"single_time": @((int)resultModel.localOCRCostTime),
            @"stay_time": @((int)durationTime),
            @"image_size": @(image.size.width * image.size.height / 1024),
            @"is_from_local_ocr": @"1"
        }];
        if (isFromUploadPhoto && resultModel.result == CJPayCardOCRResultLocalOCRFail) {
            [CJPayCardOCRUtil compressWithImage:image
                                           size:CJ_OCR_IMG_ZIP_SIZE
                                completionBlock:^(NSData * _Nonnull imageData) {
                if (self) {
                    [self p_scanWithSelectPhotoImgData:imageData];
                }
            }];
            return;
        }
        if (!self.recognizeEnable && !isFromUploadPhoto) {
            return;
        }
        if (resultModel.result == CJPayCardOCRResultLocalOCRFail) {
            return;
        }
        self.recognizeEnable = NO;
        [CJPayLoadingManager.defaultService stopLoading];
        btd_dispatch_async_on_main_queue(^{
            [self superBack];
            [self completionCallBackWithResult:resultModel];
        });
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.ocrScanView showScanLineView:YES];
    self.recognizeEnable = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)) {
    CFAbsoluteTime durationTime = (NSDate.date.timeIntervalSince1970 - self.albumAppearTime) * 1000;
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!Check_ValidArray(results)) {
        [self.ocrScanView showScanLineView:YES];
        self.recognizeEnable = YES;
        [self startSession];
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_photo_back" params:@{
            @"stay_time": @((int)durationTime),
            @"is_chooose": @"0"
        }];
        return;
    }
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self title:CJPayLocalizedStr(@"身份证读取中")];
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_photo_back" params:@{
        @"stay_time": @((int)durationTime),
        @"is_chooose": @"1"
    }];
    @CJWeakify(self);
    PHPickerResult *result = results.firstObject;
    [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error)
    {
        if (![object isKindOfClass:[UIImage class]]) {
            return;
        }
        if (@available(iOS 14.0, *)) {
            if (self.enableLocalPhotoUpload) {
                // 仅曝光
                [self p_localScanImage:(UIImage *)object isFromUploadPhoto:YES];
                return;
            }
        }
        [CJPayCardOCRUtil compressWithImage:(UIImage*)object
                                       size:CJ_OCR_IMG_ZIP_SIZE
                            completionBlock:^(NSData * _Nonnull imageData) {
            @CJStrongify(self);
            if (self) {
                [self p_scanWithSelectPhotoImgData:imageData];
            }
        }];
    }];
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    [self startSession];
    CFAbsoluteTime durationTime = (NSDate.date.timeIntervalSince1970 - self.albumAppearTime) * 1000;
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_photo_back" params:@{
        @"stay_time": @((int)durationTime),
        @"is_choose": @"0"
    }];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.enableSampleBufferDetection && CMSampleBufferDataIsReady(sampleBuffer) <= 0)
        return;
    
    if (!self.shouldCaptureImg)
        return;
    self.shouldCaptureImg = NO;
        
    if (self.isFirstSampleOutput) {
        self.isFirstSampleOutput = NO;
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_idcard_start" params:nil];
    }
    
    UIImage *image = [UIImage cj_imageFromSampleBuffer:sampleBuffer];
    if (@available(iOS 14.0, *)) {
        if (self.enableLocalScan) {
            // 仅曝光
            UIImage *croppedImage = [self p_cropImage:image];
            [self p_localScanImage:image isFromUploadPhoto:NO];
            return;
        }
    }
        
    @CJWeakify(self);
    [CJPayCardOCRUtil compressWithImage:[image copy] size:CJ_OCR_IMG_ZIP_SIZE completionBlock:^(NSData * _Nonnull imageData) {
        @CJStrongify(self);
        if (self) {
            [self p_scanWithImage:imageData];
        }
    }];
}

- (UIImage *)p_cropImage:(UIImage *)originImage {
    CGFloat aspectRatio = CJ_OCR_SCAN_WIDTH / CJ_OCR_SCAN_HEIGHT;
    CGFloat pixelWidth = originImage.size.width;
    CGFloat pixelHeight = pixelWidth / aspectRatio;
    CGFloat pixelCenterY = originImage.size.height * 4 / 9;
    CGFloat pixelOriginY = pixelCenterY - pixelHeight / 2;
    CGRect pixelRect = CGRectMake(0, pixelOriginY, pixelWidth, pixelHeight);
    return [UIImage btd_cutImage:originImage withRect:pixelRect];
}

- (void)p_scanWithImage:(NSData *)imgData {
    // 没有图片数据
    if (!imgData || !self.recognizeEnable) {
        return;
    }
    
    [self p_startRequestWithImage:imgData fromPhoto:NO];
}

- (void)p_startRequestWithImage:(NSData *)imgData fromPhoto:(BOOL)isPhoto {
    id<CJPayEngimaProtocol> engimaEngine = [CJPaySafeManager buildEngimaEngine:@""];
    NSString *ext = [CJPaySafeUtil objEncryptPWD:@"ext" engimaEngine:engimaEngine];
    NSMutableDictionary *bizParams = [self p_buildBDPayCardOCRRequestParam:imgData];
    if (self.extParams.count > 0) {
        [bizParams addEntriesFromDictionary:self.extParams];
    }
    [bizParams addEntriesFromDictionary:@{@"ext" : CJString(ext)}];
    @CJWeakify(self);
    CJPayIDCardOCRScanStatus scanStatus = CJPayIDCardOCRScanStatusProfileSide;
    self.requestCount++;
    [CJPayIDCardOCRRequest startWithScanStatus:scanStatus bizParams:bizParams completion:^(NSError * _Nonnull error, CJPayIDCardOCRResponse * _Nonnull response) {
        @CJStrongify(self);
        self.callbackCount++;
        CFAbsoluteTime startTime = isPhoto ? self.albumAppearTime : self.ocrAppearTime;
        CFAbsoluteTime durationTime = (NSDate.date.timeIntervalSince1970 - startTime) * 1000;
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_single_idcardresult" params:@{
            @"result": response.isSuccess ? @"1" : @"0",
            @"error_code": CJString(response.code),
            @"error_msg": CJString(response.msg),
            @"card_input_type": isPhoto ? @"2" : @"1",
            @"single_time": @((int)response.responseDuration),
            @"image_size": @(imgData.length / 1024),
            @"stay_time": @((int)durationTime),
            @"is_from_local_ocr": @"0"
        }];
        [[CJPayLoadingManager defaultService] stopLoading];
        if (![response isSuccess] || !self) {
            if (isPhoto) {
                [self p_alertPhotoOCRFail:@{
                    @"error_code": CJString(response.code),
                    @"error_message":CJString(response.msg)
                }];
            }
            return;
        }
        
        if (self.result == CJPayCardOCRResultSuccess) {
            return;
        }
        NSString *decrptIdNameStr = [CJPaySafeUtil objDecryptContentFromH5:CJString(response.idName)
                                                           engimaEngine:engimaEngine];
        NSString *decrptIdCodeStr = [CJPaySafeUtil objDecryptContentFromH5:CJString(response.idCode)
                                                           engimaEngine:engimaEngine];
        if (decrptIdNameStr.length && decrptIdCodeStr.length) {
            self.result = CJPayCardOCRResultSuccess;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @CJStrongify(self);
                CJPayCardOCRResultModel *resultModel = [[CJPayCardOCRResultModel alloc] initWithResult:CJPayCardOCRResultSuccess];
                resultModel.idName = decrptIdNameStr;
                resultModel.idCode = decrptIdCodeStr;
                resultModel.isFromUploadPhoto = isPhoto;
                [super superBack];
                [self completionCallBackWithResult:resultModel];
            });
        } else {
            if (isPhoto) {
                [self p_alertPhotoOCRFail:@{
                    @"error_message":decrptIdNameStr.length ? CJPayLocalizedStr(@"OCR姓名格式错误") : CJPayLocalizedStr(@"OCR身份证号码格式"),
                }];
            }
        }
    }];
}

@end

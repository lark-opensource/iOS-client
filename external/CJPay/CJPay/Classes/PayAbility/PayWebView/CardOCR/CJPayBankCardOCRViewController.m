//
//  CJPayBankCardOCRViewController.m
//  Pods
//
//  Created by youerwei on 2022/6/20.
//

#import "CJPayBankCardOCRViewController.h"

#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import <PhotosUI/PhotosUI.h>
#import "CJPayABTestManager.h"
#import "CJPayAlertUtil.h"
#import "CJPayCardOCRRequest.h"
#import "CJPayCardOCRResponse.h"
#import "CJPayLoadingManager.h"
#import "CJPayLocalCardOCRWithPitaya.h"
#import "CJPayLocalCardOCRWithVisionKit.h"
#import "CJPayNavigationBarView.h"
#import "CJPayOCRScanWindowView.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"

#define OCR_SCAN_VIEW_X_OFFSET 24
#define OCR_SCAN_VIEW_CENTER_Y_OFFSET 16

static const NSString *const kOCRErrorTipsStr = @"请将银行卡完整置于区域内";

@interface CJPayBankCardOCRViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate,PHPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic, strong) UIView *photoIconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, assign) NSTimeInterval ocrAppearTime;//记录OCR扫描页展示时间
@property (nonatomic, assign) NSTimeInterval albumAppearTime;//记录相册拉起时间
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIImageView *errorImageView;
@property (nonatomic, strong) UILabel *errorTipsLabel;
@property (nonatomic, assign) BOOL isRunningErrorTipsAnimation;
@property (nonatomic, assign) NSTimeInterval lastErrorTipsAnimationTime;//上次动画时间
@property (nonatomic, assign) BOOL errorTipsHasShowed;//是否已展示错误文案提示
@property (nonatomic, strong) MASConstraint *photoIconBottomConstraint;
@property (nonatomic, strong) MASConstraint *photoIconTopConstraint;
@property (nonatomic, assign) NSUInteger requestCount;
@property (nonatomic, assign) NSUInteger callbackCount;
@property (nonatomic, assign) BOOL isFirstSampleOutput;

@end

@implementation CJPayBankCardOCRViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (CJ_OBJECT_WITH_PROTOCOL(CJPayLocalCardOCRWithPitaya)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayLocalCardOCRWithPitaya) initEngine];
    }
    self.isFirstSampleOutput = YES;
    self.ocrAppearTime = [[NSDate date] timeIntervalSince1970];
    self.lastErrorTipsAnimationTime = [[NSDate date] timeIntervalSince1970];
    self.requestCount = 0;
    self.callbackCount = 0;
    NSString *abValue = [CJPayABTest getABTestValWithKey:CJPayABLocalOCR exposure:YES];
    NSDictionary *abDictionary = abValue.btd_jsonDictionary;
    if ([abDictionary isKindOfClass:NSDictionary.class]) {
        self.enableLocalScan = [abDictionary cj_boolValueForKey:@"enable_bank_card_scan"];
        self.enableLocalPhotoUpload = [abDictionary cj_boolValueForKey:@"enable_bank_card_upload"];
        self.serverBackupTime = [abDictionary cj_intValueForKey:@"server_backup_time" defaultValue:6];
    }
}

- (void)setupUI {
    [super setupUI];
    [self.view addSubview:self.ocrScanView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.errorTipsLabel];
    [self.view addSubview:self.errorImageView];
    [self.view addSubview:self.tipsLabel];
    [self.view addSubview:self.photoIconImageView];
    CJPayMasMaker(self.ocrScanView, {
        make.left.equalTo(self.view).offset(OCR_SCAN_VIEW_X_OFFSET);
        make.right.equalTo(self.view).offset(-OCR_SCAN_VIEW_X_OFFSET);
        make.centerY.equalTo(self.view).offset(-OCR_SCAN_VIEW_CENTER_Y_OFFSET);
        make.height.equalTo(self.ocrScanView.mas_width).multipliedBy(CJ_OCR_SCAN_HEIGHT / CJ_OCR_SCAN_WIDTH);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.navigationBar.mas_bottom).offset(30);
        make.left.equalTo(self.view).offset(12);
        make.right.equalTo(self.view).offset(-12);
        make.height.mas_equalTo(31);
    });
    
    CJPayMasMaker(self.errorTipsLabel, {
        make.bottom.equalTo(self.ocrScanView.mas_top).offset(-30);
        make.height.mas_equalTo(20);
        make.centerX.equalTo(self.view).offset(30);
    });
    CJPayMasMaker(self.errorImageView, {
        make.centerY.equalTo(self.errorTipsLabel);
        make.right.equalTo(self.errorTipsLabel.mas_left).offset(-5);
    });
    self.errorTipsLabel.hidden = YES;
    self.errorImageView.hidden = YES;
    
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

- (void)p_showOCRErrorTips:(BOOL)show {
    if (show) {
        self.errorTipsLabel.hidden = NO;
        self.errorImageView.hidden = NO;
        NSTimeInterval interval = ([[NSDate date] timeIntervalSince1970] - self.lastErrorTipsAnimationTime) * 1000;//转成毫秒
        if (!self.isRunningErrorTipsAnimation && interval >= 2000.0) { //动画至少间隔2秒
            CJPayLogInfo(@"OCR start error tips animating...");
            self.isRunningErrorTipsAnimation = YES;
            [UIView animateKeyframesWithDuration:0.5 delay:1.0 options:0 animations:^{
                [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1/5.0 animations:^{
                    self.errorTipsLabel.transform = CGAffineTransformMakeTranslation(-20.0, 0.0);
                    self.errorImageView.transform = CGAffineTransformMakeTranslation(-20.0, 0.0);
                }];
                [UIView addKeyframeWithRelativeStartTime:1/5.0 relativeDuration:1/5.0 animations:^{
                    self.errorTipsLabel.transform = CGAffineTransformMakeTranslation(40.0, 0.0);
                    self.errorImageView.transform = CGAffineTransformMakeTranslation(40.0, 0.0);;
                }];
                [UIView addKeyframeWithRelativeStartTime:2/5.0 relativeDuration:1/5.0 animations:^{
                    self.errorTipsLabel.transform = CGAffineTransformMakeTranslation(-40.0, 0.0);
                    self.errorImageView.transform = CGAffineTransformMakeTranslation(-40.0, 0.0);
                }];
                [UIView addKeyframeWithRelativeStartTime:3/5.0 relativeDuration:1/5.0 animations:^{
                    self.errorTipsLabel.transform = CGAffineTransformMakeTranslation(40.0, 0.0);
                    self.errorImageView.transform = CGAffineTransformMakeTranslation(40.0, 0.0);
                }];
                [UIView addKeyframeWithRelativeStartTime:4/5.0 relativeDuration:1/5.0 animations:^{
                    self.errorTipsLabel.transform = CGAffineTransformMakeTranslation(-20.0, 0.0);
                    self.errorImageView.transform = CGAffineTransformMakeTranslation(-20.0, 0.0);
                }];
            } completion:^(BOOL finished) {
                self.isRunningErrorTipsAnimation = NO;
                self.lastErrorTipsAnimationTime = [[NSDate date] timeIntervalSince1970];
            }];
        }
    } else {
        self.errorTipsLabel.hidden = YES;
        self.errorImageView.hidden = YES;
    }
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
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_page_click" params:@{@"button_name" : @"upload_photos"}];
    }
}

- (void)p_showImagePicker {
    self.albumAppearTime = [[NSDate date] timeIntervalSince1970];
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
    
    id<CJPayEngimaProtocol> engimaEngine = [CJPaySafeManager buildEngimaEngine:@""];

    NSString *ext = [CJPaySafeUtil objEncryptPWD:@"ext" engimaEngine:engimaEngine]; // 和后端协商对称密钥
    NSMutableDictionary *bizParams = [self p_buildBDPayCardOCRRequestParam:imgData];
    [bizParams addEntriesFromDictionary:@{@"ext" : CJString(ext)}];
    @CJWeakify(self);
    self.requestCount++;
    [CJPayCardOCRRequest startWithBizParams:bizParams completion:^(NSError * _Nonnull error, CJPayCardOCRResponse * _Nonnull response) {
        @CJStrongify(self);
        self.callbackCount++;
        NSTimeInterval durationTime = ([[NSDate date] timeIntervalSince1970] - self.albumAppearTime) * 1000;//转成毫秒
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_single_result" params:@{
            @"result": response.isSuccess ? @"1" : @"0",
            @"error_code": CJString(response.code),
            @"error_msg": CJString(response.msg),
            @"single_time": @((int)response.responseDuration),
            @"image_size": @(imgData.length / 1024),
            @"stay_time": @((int)durationTime),
            @"is_from_local_ocr": @"0"
        }];

        [[CJPayLoadingManager defaultService] stopLoading];
        if (![response isSuccess]) {
            // 弹框提示用户
            [self p_alertPhotoOCRFail:@{
                @"error_code": CJString(response.code),
                @"error_message": CJString(response.msg)
            }];
            return;
        }
        
        NSString *decrptStr = [CJPaySafeUtil objDecryptContentFromH5:CJString(response.cardNoStr) engimaEngine:engimaEngine];
        NSString *cardNoStr = [decrptStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (!self.isCardRecognized && [self p_isSatisfyRuleWithCardNoStr:cardNoStr]) {
            self.isCardRecognized = YES;
            CJPayCardOCRResultModel *resultModel = [CJPayCardOCRResultModel new];
            resultModel.result = CJPayCardOCRResultSuccess;
            resultModel.cardNoStr = CJString(cardNoStr);
            resultModel.imgData = imgData;
            resultModel.cropImgStr = response.croppedImgStr;
            resultModel.isFromUploadPhoto = YES;
            [self superBack];
            [self completionCallBackWithResult:resultModel];
        } else {
            [self p_alertPhotoOCRFail:@{
                @"error_message": @"OCR银行卡号格式错误"
            }];
        }
    }];
}

// 判断卡号是否满足OCR拉起方的要求
- (BOOL)p_isSatisfyRuleWithCardNoStr:(NSString *)cardNoStr {
    if (!Check_ValidString(cardNoStr)) {
        return NO;
    }
    
    BOOL satisfyMin = self.minLength == 0 || (self.minLength != 0 && cardNoStr.length >= self.minLength);
    BOOL satisfyMax = self.maxLength == 0 || (self.maxLength != 0 && cardNoStr.length <= self.maxLength);
    return satisfyMin && satisfyMax;
}

- (void)p_alertPhotoOCRFail:(NSDictionary *)failDetail {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:failDetail];
    [params cj_setObject:@"2" forKey:@"card_input_type"];
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_fail_pop_imp"
                        params:[params copy]];
    @CJWeakify(self);
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"无法识别，请选择清晰的银行卡照片")
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
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"无法识别银行卡") content:nil leftButtonDesc:CJPayLocalizedStr(@"重试") rightButtonDesc:CJPayLocalizedStr(@"手动输入") leftActionBlock:^{
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
        CJPayCardOCRResultModel *resultModel = [[CJPayCardOCRResultModel alloc] initWithResult:CJPayCardOCRResultUserManualInput];
        resultModel.isFromUploadPhoto = NO;
        resultModel.errorMessage = errorMessage;
        [self completionCallBackWithResult:resultModel];
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
    NSTimeInterval startTime = resultModel.isFromUploadPhoto ? self.albumAppearTime : self.ocrAppearTime;
    NSTimeInterval durationTime = ([[NSDate date] timeIntervalSince1970] - startTime)*1000;//转成毫秒
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_result"
                    params:@{@"result": resultModel.result == CJPayCardOCRResultSuccess ? @"1" : @"0",
                             @"card_input_type": resultModel.isFromUploadPhoto ? @"2" : @"1",
                             @"is_from_local_ocr": resultModel.isFromLocalOCR ? @"1" : @"0",
                             @"stay_time": @((int)durationTime),
                             @"error_code": CJString(resultModel.errorCode),
                             @"error_message": CJString(resultModel.errorMessage),
                             @"request_count": @(self.requestCount),
                             @"callback_count": @(self.callbackCount),
                             @"num_length": @(resultModel.cardNoStr.length)
                           }];
}

- (NSMutableDictionary *)p_buildBDPayCardOCRRequestParam:(NSData *)imgData {
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:self.appId forKey:@"app_id"];
    [bizParams cj_setObject:self.merchantId forKey:@"merchant_id"];
    
    NSString *imgBase64Str = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [bizParams cj_setObject:[CJPaySafeUtil encryptField:imgBase64Str] forKey:@"img_data"];
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
        _titleLabel.text = CJPayLocalizedStr(@"扫描银行卡，快速识别银行卡号");
    }
    return _titleLabel;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.font = [UIFont cj_fontOfSize:12];
        _tipsLabel.textColor = [UIColor whiteColor];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.text = CJPayLocalizedStr(@"将银行卡卡号面置于此区域，并对齐扫描框边缘");
    }
    return _tipsLabel;
}

- (UIImageView *)errorImageView {
    if (!_errorImageView) {
        _errorImageView = [UIImageView new];
        [_errorImageView cj_setImage:@"cj_warning_tips_icon"];
    }
    return _errorImageView;
}

- (UILabel *)errorTipsLabel {
    if (!_errorTipsLabel) {
        _errorTipsLabel = [UILabel new];
        _errorTipsLabel.font = [UIFont cj_fontOfSize:12];
        _errorTipsLabel.textColor = [UIColor whiteColor];
        _errorTipsLabel.textAlignment = NSTextAlignmentCenter;
        _errorTipsLabel.text = CJPayLocalizedStr(kOCRErrorTipsStr);
    }
    return _errorTipsLabel;
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    NSTimeInterval durationTime = ([[NSDate date] timeIntervalSince1970] - self.albumAppearTime)*1000;//转成毫秒
    UIImage *image = [info cj_objectForKey:UIImagePickerControllerOriginalImage];
    if (![image isKindOfClass:UIImage.class]) {
        [self startSession];
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_photo_back" params:@{
            @"stay_time": @((int)durationTime),
            @"is_choose": @"0"
        }];
        return;
    }
    
    @CJWeakify(self);
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_photo_back" params:@{
        @"stay_time": @((int)durationTime),
        @"is_choose": @"1"
    }];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self title:CJPayLocalizedStr(@"银行卡读取中")];
    if (@available(iOS 13.0, *)) {
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

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.ocrScanView showScanLineView:YES];
    self.recognizeEnable = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate
- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)) {
    NSTimeInterval durationTime = ([[NSDate date] timeIntervalSince1970] - self.albumAppearTime)*1000;//转成毫秒
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!Check_ValidArray(results)) {
        [self.ocrScanView showScanLineView:YES];
        self.recognizeEnable = YES;
        [self startSession];
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_photo_back" params:@{
            @"stay_time": @((int)durationTime),
            @"is_choose": @"0"
        }];

        return;
    }
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self title:CJPayLocalizedStr(@"银行卡读取中")];
    @CJWeakify(self);
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_photo_back" params:@{
        @"stay_time": @((int)durationTime),
        @"is_choose": @"1"
    }];
    PHPickerResult *result = results.firstObject;
    [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error)
     {
        if (![object isKindOfClass:[UIImage class]]) {
            return;
        }
        UIImage *image = (UIImage *)object;
        if (@available(iOS 13.0, *)) {
            if (self.enableLocalPhotoUpload) {
                // 仅曝光
                [self p_localScanImage:image isFromUploadPhoto:YES];
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

- (void)p_localScanImage:(UIImage *)image isFromUploadPhoto:(BOOL)isFromUploadPhoto API_AVAILABLE(ios(13)){
    self.requestCount++;
    [CJ_OBJECT_WITH_PROTOCOL(CJPayLocalCardOCRWithVisionKit) recognizeBankCardWithImage:image isFromUploadPhoto:isFromUploadPhoto completion:^(CJPayCardOCRResultModel * _Nullable resultModel) {
        self.callbackCount++;
        NSTimeInterval startTime = resultModel.isFromUploadPhoto ? self.albumAppearTime : self.ocrAppearTime;
        NSTimeInterval durationTime = ([[NSDate date] timeIntervalSince1970] - startTime)*1000;//转成毫秒
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_single_result" params:@{
            @"result": resultModel.result == CJPayCardOCRResultSuccess ? @"1" : @"0",
            @"card_input_type": resultModel.isFromUploadPhoto ? @"2" : @"1",
            @"image_size": @(image.size.width * image.size.height / 1024),
            @"single_time": @((int)resultModel.localOCRCostTime),
            @"stay_time": @((int)durationTime),
            @"num_length": @(resultModel.cardNoStr.length),
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

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    [self startSession];
    NSTimeInterval durationTime = ([[NSDate date] timeIntervalSince1970] - self.albumAppearTime)*1000;//转成毫秒
    [self trackWithEventName:@"wallet_addbcard_orc_scanning_photo_back" params:@{
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
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_start" params:nil];
    }

    UIImage *image = [UIImage cj_imageFromSampleBuffer:sampleBuffer];
    image = [UIImage btd_fixImgOrientation:image]; // 修复图片朝向
    
    if (@available(iOS 13.0, *)) {
        if (self.enableLocalScan) { // AB实验：本地VisionKit检测
            // 仅曝光
            UIImage *croppedImage = [self p_cropImage:image];
            [self p_localScanImage:croppedImage isFromUploadPhoto:NO];
            return;
        }
    }
    
    [self p_compressAndUploadImage:image];
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

- (void)p_compressAndUploadImage:(UIImage *)image {
    @CJWeakify(self);
    [CJPayCardOCRUtil compressWithImage:[image copy] size:CJ_OCR_IMG_ZIP_SIZE completionBlock:^(NSData * _Nonnull imageData) {
        @CJStrongify(self);
        if (self) {
            [self p_scanWithImage:imageData];
        }
    }];
}

- (void)p_scanWithImage:(NSData *)imgData {
    // 没有图片数据
    if (!imgData) {
        return;
    }
    
    if (!self.recognizeEnable) {
        return;
    }
    
    id<CJPayEngimaProtocol> engimaEngine = [CJPaySafeManager buildEngimaEngine:@""];
    NSString *ext = [CJPaySafeUtil objEncryptPWD:@"ext" engimaEngine:engimaEngine]; // 和后端协商对称密钥
    NSMutableDictionary *bizParams = [self p_buildBDPayCardOCRRequestParam:imgData];
    [bizParams addEntriesFromDictionary:@{@"ext" : CJString(ext)}];
    @CJWeakify(self);
    CJPayLogInfo(@"bank card scan start network request...");
    self.requestCount++;
    NSTimeInterval requestStartTime = [[NSDate date] timeIntervalSince1970];
    [CJPayCardOCRRequest startWithBizParams:bizParams completion:^(NSError * _Nonnull error, CJPayCardOCRResponse * _Nonnull response) {
        @CJStrongify(self);
        self.callbackCount++;
        NSTimeInterval durationTime = ([[NSDate date] timeIntervalSince1970] - self.ocrAppearTime)*1000;//转成毫秒
        [self trackWithEventName:@"wallet_addbcard_orc_scanning_single_result" params:@{
            @"result": response.isSuccess ? @"1" : @"0",
            @"error_code": CJString(response.code),
            @"error_msg": CJString(response.msg),
            @"single_time": @((int)response.responseDuration),
            @"image_size": @(imgData.length / 1024),
            @"stay_time": @((int)durationTime),
            @"is_from_local_ocr": @"0"
        }];
        
        CJPayLogInfo(@"OCR response, code: %@, msg: %@", response.code, response.msg);
        if (![response isSuccess] || !self) {
            [CJMonitor trackServiceAllInOne:@"wallet_rd_bank_card_ocr_fail"
                                     metric:@{}
                                   category:@{@"code": CJString(response.code),
                                              @"msg": CJString(response.msg)}
                                      extra:@{}];
            // MP020349 图片中银行卡片被截断
            if ([response.code isEqualToString:@"MP020349"]) {
                NSTimeInterval requestDurationTime = ([[NSDate date] timeIntervalSince1970] - requestStartTime) * 1000; //毫秒
                if (requestDurationTime <= 2000.0) { // 两秒内才提示
                    [self p_showOCRErrorTips:YES];
                    if (!self.errorTipsHasShowed) {
                        self.errorTipsHasShowed = YES;
                        [self trackWithEventName:@"wallet_addbcard_orc_scanning_page_title_imp" params:@{
                            @"title": kOCRErrorTipsStr,
                            @"error_code": response.code ?: @"",
                            @"error_msg": response.msg ?: @""
                        }];
                    }
                }
            }
            return;
        }
        
        [self p_showOCRErrorTips:NO];
        
        NSString *decrptStr = [CJPaySafeUtil objDecryptContentFromH5:CJString(response.cardNoStr) engimaEngine:engimaEngine];
        NSString *cardNoStr = [decrptStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (!self.isCardRecognized && [self p_isSatisfyRuleWithCardNoStr:cardNoStr] && self.recognizeEnable) {
            self.isCardRecognized = YES;
            self.recognizeEnable = NO;
            CJPayCardOCRResultModel *resultModel = [CJPayCardOCRResultModel new];
            resultModel.result = CJPayCardOCRResultSuccess;
            resultModel.cardNoStr = CJString(cardNoStr);
            resultModel.imgData = imgData;
            resultModel.cropImgStr = response.croppedImgStr;
            [self superBack]; // 这里不直接调用super，主要是解决强持有的问题
            [self completionCallBackWithResult:resultModel];
        }
    }];
}

@end

//
//  CJPayIDCardOCRViewController.m
//  CJPay
//
//  Created by youerwei on 2022/6/21.
//

#import "CJPayIDCardOCRViewController.h"
#import "CJPayIDCardOCRRequest.h"
#import "CJPayAlertUtil.h"
#import "CJPayLoadingManager.h"
#import "CJPayModifyMemberElementsRequest.h"
#import "CJPayCardOCRResultModel.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayToast.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPaySDKJSONRequestSerializer.h"
#import "CJPayJSONResponseSerializer.h"
#import "CJPayRequestParam.h"

@interface CJPayIDCardOCRViewController ()

@property (nonatomic, strong) UIImageView *profileSideImage;
@property (nonatomic, strong) UIImageView *emblemSideImage;
@property (nonatomic, strong) UIImageView *profileIcon;
@property (nonatomic, strong) UIImageView *emblemIcon;

@property (nonatomic, assign) CJPayIDCardOCRScanStatus scanStatus;
@property (nonatomic, copy) NSString *profileSideFlowNo;
@property (nonatomic, copy) NSString *emblemSideFlowNo;
@property (nonatomic, strong) UILabel *tipsLabel;

@property (nonatomic, strong) NSMutableDictionary *fxjResponseDict;

@end

@implementation CJPayIDCardOCRViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _scanStatus = CJPayIDCardOCRScanStatusProfileSide;
        _isFxjCustomize = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.profileIcon.hidden = NO;
    self.ocrType = CJPayOCRTypeIDCard;
    self.safeGuardTipView.showEnable = !self.isFxjCustomize;
    [self p_trackWithEventName:@"wallet_identified_verification_imp" param:@{}];
    [self p_trackWithEventName:@"wallet_identified_verification_click" param:@{
        @"type": @"front"
    }];
    // Do any additional setup after loading the view.
}

- (void)setupUI {
    [super setupUI];
    [self.view addSubview:self.tipsLabel];
    [self.view addSubview:self.ocrScanView];
    [self.view addSubview:self.profileSideImage];
    [self.view addSubview:self.emblemSideImage];
    [self.view addSubview:self.profileIcon];
    [self.view addSubview:self.emblemIcon];
    
    CJPayMasMaker(self.ocrScanView, {
        make.left.equalTo(self.view).offset(24);
        make.right.equalTo(self.view).offset(-24);
        make.centerY.equalTo(self.view).offset(-126);
        make.height.equalTo(self.ocrScanView.mas_width).multipliedBy(CJ_OCR_SCAN_HEIGHT / CJ_OCR_SCAN_WIDTH);
    });
    
    CJPayMasMaker(self.tipsLabel, {
        make.left.right.equalTo(self.ocrScanView);
        make.top.equalTo(self.ocrScanView.mas_bottom).offset(28);
    });
    
    CJPayMasMaker(self.profileSideImage, {
        make.left.equalTo(self.ocrScanView);
        make.right.equalTo(self.view.mas_centerX).offset(-7.5);
        make.top.equalTo(self.tipsLabel.mas_bottom).offset(40);
        make.height.equalTo(self.profileSideImage.mas_width).multipliedBy(96.0 / 156.0);
    });
    
    CJPayMasMaker(self.emblemSideImage, {
        make.left.equalTo(self.view.mas_centerX).offset(7.5);
        make.right.equalTo(self.ocrScanView);
        make.top.height.equalTo(self.profileSideImage);
    });
    
    CJPayMasMaker(self.profileIcon, {
        make.width.equalTo(self.ocrScanView.mas_width).dividedBy(372.0 / 88.0);
        make.height.equalTo(self.profileIcon.mas_width).multipliedBy(100.0 / 88.0);
        make.top.equalTo(self.ocrScanView).offset(40);
        make.right.equalTo(self.ocrScanView).offset(-28);
    });
    
    CJPayMasMaker(self.emblemIcon, {
        make.width.equalTo(self.ocrScanView.mas_width).dividedBy(372.0 / 88.0);
        make.height.equalTo(self.emblemIcon.mas_width);
        make.top.equalTo(self.ocrScanView).offset(40);
        make.left.equalTo(self.ocrScanView).offset(28);
    });
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.enableSampleBufferDetection && CMSampleBufferDataIsReady(sampleBuffer) <= 0) return;
    
    if (self.shouldCaptureImg) {
        self.shouldCaptureImg = NO;
        UIImage *image = [UIImage cj_imageFromSampleBuffer:sampleBuffer];
       
        @CJWeakify(self);
        [CJPayCardOCRUtil compressWithImage:[image copy] size:self.compressSize completionBlock:^(NSData * _Nonnull imageData) {
            @CJStrongify(self);
            if (self) {
                [self p_scanWithImage:imageData];
            }
        }];
    }
}

- (void)p_scanWithImage:(NSData *)imgData {
    // 没有图片数据
    if (!imgData) {
        return;
    }
    
    if (!self.recognizeEnable) {
        return;
    }
    
    NSMutableDictionary *bizParams = [self p_buildBDPayIDCardOCRRequestParam:imgData];
    CJPayIDCardOCRScanStatus scanStatus = self.scanStatus;
    @CJWeakify(self);
    [self p_startRequestWithScanStatus:scanStatus bizParam:bizParams completion:^(BOOL isSuccess, NSString * _Nullable flowNo) {
        @CJStrongify(self)
        if (!isSuccess || !self) {
            return;
        }
        if (self.isCardRecognized || !self.recognizeEnable) {
            return;
        }
        if (scanStatus != self.scanStatus) {
            return;
        }
        if (self.scanStatus == CJPayIDCardOCRScanStatusProfileSide) {
            [self.profileSideImage cj_setImage:@"cj_profile_side_complete_image"];
            self.profileSideFlowNo = flowNo;
            self.tipsLabel.text = CJPayLocalizedStr(@"将身份证国徽面置于此区域，并对齐扫描框边缘");
            self.scanStatus = CJPayIDCardOCRScanStatusEmblemSide;
            self.profileIcon.hidden = YES;
            self.emblemIcon.hidden = NO;
        
            [self p_trackWithEventName:@"wallet_identified_verification_upload_click" param:@{
                @"type": @"front",
                @"result": @1,
            }];
            [self p_trackWithEventName:@"wallet_identified_verification_click" param:@{
                @"type": @"back"
            }];
        } else {
            [self.emblemSideImage cj_setImage:@"cj_emblem_side_complete_image"];
            self.isCardRecognized = YES;
            self.recognizeEnable = NO;
            self.emblemSideFlowNo = flowNo;
            
            [self p_trackWithEventName:@"wallet_identified_verification_upload_click" param:@{
                @"type": @"back",
                @"result": @1,
            }];
            if (self.isFxjCustomize) {
                CJPayCardOCRResultModel *resultModel = CJPayCardOCRResultModel.new;
                resultModel.result = CJPayCardOCRResultSuccess;
                resultModel.fxjResponseDict = self.fxjResponseDict;
                [self superBack];
                CJ_CALL_BLOCK(self.completionBlock, resultModel);
            } else {
                [self p_modifyMemberElements];
            }
        }
    }];
}

- (void)p_startRequestWithScanStatus:(CJPayIDCardOCRScanStatus)scanStatus bizParam:(NSDictionary *)bizParam completion:(void (^)(BOOL isSuccess, NSString * _Nullable flowNo))completion {
    if (self.isFxjCustomize) {
        NSString *requestUrl = scanStatus == CJPayIDCardOCRScanStatusProfileSide ? self.frontRequestUrl : self.backRequestUrl;
        @CJWeakify(self)
        NSMutableDictionary *headerDic = [NSMutableDictionary new];
        if ([CJPayRequestParam isSaasEnv]) {
            NSString *accessToken = [CJPayRequestParam accessToken];
            [headerDic cj_setObject:CJString(accessToken) forKey:@"bd-ticket-guard-target"];//增加开放平台证书
            NSString *bearerAccessToken = [NSString stringWithFormat:@"Bearer %@", CJString(accessToken)]; //用户鉴权信息为Bearer XXX
            [headerDic cj_setObject:CJString(bearerAccessToken) forKey:@"authorization"];
        }
        [TTNetworkManager.shareInstance requestForJSONWithResponse:requestUrl params:bizParam method:@"POST" needCommonParams:NO headerField:[headerDic copy] requestSerializer:CJPaySDKJSONRequestSerializer.class responseSerializer:CJPayJSONResponseSerializer.class autoResume:YES callback:^(NSError * _Nullable error, id  _Nullable obj, TTHttpResponse * _Nullable response) {
            
            @CJStrongify(self)
            if (!self || ![obj isKindOfClass:NSDictionary.class]) {
                return;
            }
            NSDictionary *responseDict = (NSDictionary *)obj;
            NSInteger code = [responseDict cj_integerValueForKey:@"code"];
            NSDictionary *data = [responseDict cj_dictionaryValueForKey:@"data"];
            NSInteger ocrStatus = [data cj_integerValueForKey:@"ocr_status"];
            if (code != 0 || ![@[@(100), @(108), @(109)] containsObject:@(ocrStatus)]) {
                return;
            }
            [self.fxjResponseDict cj_setObject:data forKey:scanStatus == CJPayIDCardOCRScanStatusProfileSide ? @"front_data" : @"back_data"];
            CJ_CALL_BLOCK(completion, YES, nil);
        }];
    } else {
        @CJWeakify(self);
        [CJPayIDCardOCRRequest startWithScanStatus:scanStatus bizParams:bizParam completion:^(NSError * _Nonnull error, CJPayIDCardOCRResponse * _Nonnull response) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(completion, response.isSuccess, response.flowNo);
        }];
    }
}

- (void)p_modifyMemberElements {
    NSDictionary *bizParam = @{
        @"app_id": CJString(self.appId),
        @"merchant_id": CJString(self.merchantId),
        @"id_type": @"ID_CARD",
        @"id_photo_front_upload_flow_no": CJString(self.profileSideFlowNo),
        @"id_photo_back_upload_flow_no": CJString(self.emblemSideFlowNo)
    };
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self title:CJPayLocalizedStr(@"上传中")];
    @CJWeakify(self)
    [CJPayModifyMemberElementsRequest startWithBizParams:bizParam completion:^(NSError * _Nonnull error, CJPayModifyMemberElementsResponse * _Nonnull response) {
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] stopLoading];
        
        if ([response isSuccess]) {
            [CJToast toastText:CJPayLocalizedStr(@"上传成功") duration:1.5 inWindow:self.cj_window];
            [self p_trackWithEventName:@"wallet_identified_verification_submit" param:@{
                @"result": @1
            }];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                CJPayCardOCRResultModel *resultModel = [[CJPayCardOCRResultModel alloc] initWithResult:CJPayCardOCRResultSuccess];
                [self superBack];
                CJ_CALL_BLOCK(self.completionBlock, resultModel);
            });
            return;
        }
        
        if (response.buttonInfo) {
            response.buttonInfo.code = response.code;
            CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
            
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo fromVC:self errorMsg:response.msg withActions:actionModel withAppID:self.appId merchantID:self.merchantId];
            
            [self p_trackWithEventName:@"wallet_identified_verification_submit" param:@{
                @"result": @0,
                @"error_reason": CJString(response.buttonInfo.page_desc)
            }];
            return;
        }
        
        [CJToast toastText:Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage duration:1.5 inWindow:self.cj_window];
        [self p_trackWithEventName:@"wallet_identified_verification_submit" param:@{
            @"result": @0,
            @"error_reason": CJString(response.msg)
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CJPayCardOCRResultModel *resultModel = [[CJPayCardOCRResultModel alloc] initWithResult:CJPayCardOCRResultIDCardModifyElementsFail];
            [self superBack];
            CJ_CALL_BLOCK(self.completionBlock, resultModel);
        });
        
    }];
}

- (void)alertTimeOut {
    [super alertTimeOut];
    
    NSString *alertTitle = @"";
    NSString *trackType = @"";
    switch (self.scanStatus) {
        case CJPayIDCardOCRScanStatusProfileSide:
            alertTitle = CJPayLocalizedStr(@"扫描失败，请扫描身份证人像面");
            trackType = @"front";
            break;
        case CJPayIDCardOCRScanStatusEmblemSide:
            alertTitle = CJPayLocalizedStr(@"扫描失败，请扫描身份证国徽面");
            trackType = @"back";
        default:
            break;
    }
    
    @CJWeakify(self);
    [CJPayAlertUtil customSingleAlertWithTitle:alertTitle content:nil buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:^{
        @CJStrongify(self);
        [self.alertTimer fire];
        self.recognizeEnable = YES;
    } useVC:self];
    
    [self p_trackWithEventName:@"wallet_identified_verification_upload_click" param:@{
        @"type": CJString(trackType),
        @"result": @0,
        @"error_reason": CJString(alertTitle)
    }];
}

- (NSMutableDictionary *)p_buildBDPayIDCardOCRRequestParam:(NSData *)imgData {
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    if (self.isFxjCustomize) {
        NSString *media = nil;
        BOOL isNeedEncrypt = Check_ValidString(self.isecKey);
        NSNumber *enigmaVersion = nil;
        if (isNeedEncrypt && imgData) { //图片加密
            media = [CJPaySafeManager encryptMediaData:imgData tfccCert:@"" iSecCert:self.isecKey engimaVersion:&enigmaVersion];
        }
        [bizParams cj_setObject:media forKey:@"media"];
        [bizParams cj_setObject:enigmaVersion forKey:@"enigma_version"];
        [bizParams cj_setObject:self.isecKey forKey:@"public_key"];
        return bizParams;
    } else {
        [bizParams cj_setObject:self.appId forKey:@"app_id"];
        [bizParams cj_setObject:self.merchantId forKey:@"merchant_id"];
        [bizParams cj_setObject:@"ID_CARD" forKey:@"id_type"];
        
        NSString *imgBase64Str = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        NSString *imgSrcStr = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", imgBase64Str];
        [bizParams cj_setObject:[CJPaySafeUtil encryptField:imgSrcStr] forKey:@"id_photo"];
        if (self.extParams.count > 0) {
            [bizParams addEntriesFromDictionary:self.extParams];
        }
        return bizParams;
    }
}

- (void)p_trackWithEventName:(NSString *)eventName param:(NSDictionary *)param {
    NSMutableDictionary *dic = [@{
        @"upload_type": @"scan"
    } mutableCopy];
    [dic addEntriesFromDictionary:param];
    
    [self trackWithEventName:eventName params:dic];
}

- (UIImageView *)profileSideImage {
    if (!_profileSideImage) {
        _profileSideImage = [UIImageView new];
        [_profileSideImage cj_setImage:@"cj_profile_side_blank_image"];
    }
    return _profileSideImage;
}

- (UIImageView *)emblemSideImage {
    if (!_emblemSideImage) {
        _emblemSideImage = [UIImageView new];
        [_emblemSideImage cj_setImage:@"cj_emblem_side_blank_image"];
    }
    return _emblemSideImage;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.font = [UIFont cj_fontOfSize:14];
        _tipsLabel.textColor = [UIColor cj_colorWithHexString:@"#FFFFFF" alpha:0.8];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.text = CJPayLocalizedStr(@"将身份证人像面置于此区域，并对齐扫描框边缘");
    }
    return _tipsLabel;
}

- (UIImageView *)profileIcon {
    if (!_profileIcon) {
        _profileIcon = [UIImageView new];
        [_profileIcon cj_setImage:@"cj_id_card_profile_icon"];
        _profileIcon.hidden = YES;
    }
    return _profileIcon;
}

- (UIImageView *)emblemIcon {
    if (!_emblemIcon) {
        _emblemIcon = [UIImageView new];
        [_emblemIcon cj_setImage:@"cj_id_card_emblem_icon"];
        _emblemIcon.hidden = YES;
    }
    return _emblemIcon;
}

- (NSUInteger)compressSize {
    if (_compressSize < 10) {
        return 150;
    }
    
    return _compressSize;
}

- (NSMutableDictionary *)fxjResponseDict {
    if (!_fxjResponseDict) {
        _fxjResponseDict = NSMutableDictionary.dictionary;
    }
    return _fxjResponseDict;
}

@end

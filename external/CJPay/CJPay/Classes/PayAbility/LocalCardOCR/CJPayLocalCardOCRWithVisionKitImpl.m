//
//  CJPayLocalCardOCRWithVisionKitImpl.m
//  CJPaySandBox
//
//  Created by Emile on 2023/4/20.
//

#import "CJPayLocalCardOCRWithVisionKitImpl.h"

#import <ByteDanceKit/ByteDanceKit.h>
#import <PIPOVisionOCRKit/PIPOVisionOCRKit-Swift.h>
#import "CJPayCardOCRResultModel.h"
#import "CJPayLocalCardOCRWithVisionKit.h"
#import "CJPaySDKMacro.h"
#import "UIImage+CJPay.h"

@interface CJPayLocalCardOCRWithVisionKitImpl ()<CJPayLocalCardOCRWithVisionKit>

@property (nonatomic, strong) CCDCVisionTextService *ccdcTextService;
@property (nonatomic, strong) CNIDCardVisionTextService *idCardTextService API_AVAILABLE(ios(14));
@property (nonatomic, assign) NSUInteger photoUploadFailTimes;

@end

@implementation CJPayLocalCardOCRWithVisionKitImpl

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassToPtocol(self, CJPayLocalCardOCRWithVisionKit)
})

- (void)recognizeIDCardWithImage:(UIImage *)image isFromUploadPhoto:(BOOL)isFromUploadPhoto completion:(void (^)(CJPayCardOCRResultModel * _Nonnull))completion API_AVAILABLE(ios(14)) {
    if (!isFromUploadPhoto) {
        [self p_recognizeIDCardWithImage:image isFromUploadPhoto:isFromUploadPhoto completion:completion];
        return;
    }
    // fix image orientation (set to UIImageOrientationUp)
    UIImage *compressedImage = [UIImage btd_tryCompressImage:image ifImageSizeLargeTargetSize:CGSizeMake(2560, 2560)];
    btd_dispatch_async_on_main_queue(^{
        for (int i = 0; i < 4; i++) {
            UIImage *finalImage = [UIImage btd_imageRotatedByRadians:i * M_PI_2 originImg:compressedImage];
            [self p_recognizeIDCardWithImage:finalImage isFromUploadPhoto:isFromUploadPhoto completion:completion];
        }
    });
}

- (void)p_recognizeIDCardWithImage:(UIImage *)image isFromUploadPhoto:(BOOL)isFromUploadPhoto completion:(void (^)(CJPayCardOCRResultModel * _Nonnull))completion API_AVAILABLE(ios(14)) {
    @CJWeakify(self)
    CFAbsoluteTime startTime = NSDate.date.timeIntervalSince1970;
    self.idCardTextService.completionBlock = ^(CNIDCardRecognizeModel * _Nonnull recognizeModel) {
        @CJStrongify(self)
        CJPayCardOCRResultModel *resultModel = CJPayCardOCRResultModel.new;
        resultModel.result = CJPayCardOCRResultSuccess;
        resultModel.idName = recognizeModel.idCardName;
        resultModel.idCode = recognizeModel.idCardNumber;
        resultModel.isFromUploadPhoto = isFromUploadPhoto;
        resultModel.isFromLocalOCR = YES;
        resultModel.localOCRCostTime = (NSDate.date.timeIntervalSince1970 - startTime) * 1000;
        CJ_CALL_BLOCK(completion, resultModel);
        [self p_clearIdCardTextService];
    };
    self.idCardTextService.failCompletionBlock = ^(NSError * _Nullable error) {
        @CJStrongify(self)
        CJPayCardOCRResultModel *resultModel = CJPayCardOCRResultModel.new;
        resultModel.result = CJPayCardOCRResultLocalOCRFail;
        resultModel.isFromUploadPhoto = isFromUploadPhoto;
        resultModel.isFromLocalOCR = YES;
        resultModel.localOCRCostTime = (NSDate.date.timeIntervalSince1970 - startTime) * 1000;
        if (!isFromUploadPhoto) {
            CJ_CALL_BLOCK(completion, resultModel);
            return;
        }
        self.photoUploadFailTimes++;
        if (self.photoUploadFailTimes >= 4) {
            CJ_CALL_BLOCK(completion, resultModel);
            [self p_clearIdCardTextService];
        }
    };
    [self.idCardTextService recognizeIDCardTextInCardImage:image];
}

- (void)recognizeBankCardWithImage:(UIImage *)image isFromUploadPhoto:(BOOL)isFromUploadPhoto completion:(void (^)(CJPayCardOCRResultModel * _Nonnull))completion API_AVAILABLE(ios(13)) {
    if (!isFromUploadPhoto) {
        [self p_recognizeBankCardWithImage:image isFromUploadPhoto:isFromUploadPhoto completion:completion];
        return;
    }
    UIImage *compressedImage = [UIImage btd_tryCompressImage:image ifImageSizeLargeTargetSize:CGSizeMake(2560, 2560)];
    btd_dispatch_async_on_main_queue(^{
        for (int i = 0; i < 4; i++) {
            UIImage *finalImage = [UIImage btd_imageRotatedByRadians:i * M_PI_2 originImg:compressedImage];
            [self p_recognizeBankCardWithImage:finalImage isFromUploadPhoto:isFromUploadPhoto completion:completion];
        }
    });
}

- (void)p_recognizeBankCardWithImage:(UIImage *)image isFromUploadPhoto:(BOOL)isFromUploadPhoto completion:(void (^)(CJPayCardOCRResultModel * _Nonnull))completion API_AVAILABLE(ios(13)) {
    @CJWeakify(self)
    CFAbsoluteTime startTime = NSDate.date.timeIntervalSince1970;
    self.ccdcTextService.completionBlock = ^(CCDCVisionRecognizeModel * _Nonnull recognizeModel) {
        @CJStrongify(self)
        CJPayCardOCRResultModel *resultModel = CJPayCardOCRResultModel.new;
        resultModel.result = CJPayCardOCRResultSuccess;
        resultModel.cardNoStr = recognizeModel.cardNumber;
        resultModel.cropImgStr = [UIImageJPEGRepresentation(recognizeModel.cardNumberCropImage, 0.3) base64EncodedStringWithOptions:0];
        resultModel.isFromLocalOCR = YES;
        resultModel.isFromUploadPhoto = isFromUploadPhoto;
        resultModel.localOCRCostTime = (NSDate.date.timeIntervalSince1970 - startTime) * 1000;
        CJ_CALL_BLOCK(completion, resultModel);
        [self p_clearCcdcTextService];
    };
    self.ccdcTextService.failCompletionBlock = ^(NSError * _Nullable error) {
        @CJStrongify(self)
        CJPayCardOCRResultModel *resultModel = CJPayCardOCRResultModel.new;
        resultModel.result = CJPayCardOCRResultLocalOCRFail;
        resultModel.isFromUploadPhoto = isFromUploadPhoto;
        resultModel.localOCRCostTime = (NSDate.date.timeIntervalSince1970 - startTime) * 1000;
        resultModel.isFromLocalOCR = YES;
        if (!isFromUploadPhoto) {
            CJ_CALL_BLOCK(completion, resultModel);
            return;
        }
        self.photoUploadFailTimes++;
        if (self.photoUploadFailTimes >= 4) {
            CJ_CALL_BLOCK(completion, resultModel);
            [self p_clearCcdcTextService];
        }
    };
    [self.ccdcTextService recognizeTextInCardImage:image];
}

- (void)p_clearIdCardTextService API_AVAILABLE(ios(14)){
    self.idCardTextService.completionBlock = nil;
    self.idCardTextService.failCompletionBlock = nil;
    self.idCardTextService = nil;
    self.photoUploadFailTimes = 0;
}

- (void)p_clearCcdcTextService {
    self.ccdcTextService.completionBlock = nil;
    self.ccdcTextService.failCompletionBlock = nil;
    self.ccdcTextService = nil;
    self.photoUploadFailTimes = 0;
}

- (CCDCVisionTextService *)ccdcTextService {
    if (!_ccdcTextService) {
        _ccdcTextService = CCDCVisionTextService.new;
        _ccdcTextService.resultValidateStrategy = ResultValidateStrategyOnlyCardNumber;
    }
    return _ccdcTextService;
}

- (CNIDCardVisionTextService *)idCardTextService {
    if (!_idCardTextService) {
        _idCardTextService = CNIDCardVisionTextService.new;
    }
    return _idCardTextService;
}

@end

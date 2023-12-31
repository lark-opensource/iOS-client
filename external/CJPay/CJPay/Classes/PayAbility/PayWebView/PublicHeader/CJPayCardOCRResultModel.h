//
//  CJPayCardOCRResultModel.h
//  CJPay
//
//  Created by 尚怀军 on 2020/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayCardOCRResult) {
    CJPayCardOCRResultUserCancel,
    CJPayCardOCRResultUserManualInput,
    CJPayCardOCRResultBackNoCameraAuthority,
    CJPayCardOCRResultBackNoJumpSettingAuthority,
    CJPayCardOCRResultSuccess,
    CJPayCardOCRResultIDCardModifyElementsFail,
    CJPayCardOCRResultRetry,
    CJPayCardOCRResultLocalOCRFail,
};

@interface CJPayCardOCRResultModel : NSObject

@property (nonatomic, assign) CJPayCardOCRResult result;
@property (nonatomic, copy) NSString *cardNoStr;
@property (nonatomic, strong) NSData *imgData;
@property (nonatomic, copy) NSString *cropImgStr;
@property (nonatomic, assign) BOOL isFromUploadPhoto;

@property (nonatomic, assign) BOOL isFromLocalOCR;
@property (nonatomic, assign) CFAbsoluteTime localOCRCostTime;

@property (nonatomic, copy) NSString *idName;
@property (nonatomic, copy) NSString *idCode;

@property (nonatomic, copy) NSString *errorCode;
@property (nonatomic, copy) NSString *errorMessage;

@property (nonatomic, strong) NSDictionary *fxjResponseDict;

- (instancetype)initWithResult:(CJPayCardOCRResult)result;

@end

NS_ASSUME_NONNULL_END

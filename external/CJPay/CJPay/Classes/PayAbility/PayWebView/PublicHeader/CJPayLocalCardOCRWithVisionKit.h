//
//  CJPayLocalCardOCRWithVisionKit.h
//  CJPaySandBox_1
//
//  Created by Emile on 2023/4/20.
//

#ifndef CJPayLocalCardOCRWithVisionKit_h
#define CJPayLocalCardOCRWithVisionKit_h
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayCardOCRResultModel;

// 使用VisionKit对银行卡进行本地OCR
@protocol CJPayLocalCardOCRWithVisionKit <NSObject>

- (void)recognizeBankCardWithImage:(UIImage *)image isFromUploadPhoto:(BOOL)isFromUploadPhoto completion:(void (^)(CJPayCardOCRResultModel * _Nonnull))completion API_AVAILABLE(ios(13));
- (void)recognizeIDCardWithImage:(UIImage *)image isFromUploadPhoto:(BOOL)isFromUploadPhoto completion:(void (^)(CJPayCardOCRResultModel * _Nonnull))completion API_AVAILABLE(ios(14));

@end

NS_ASSUME_NONNULL_END
#endif /* CJPayLocalCardOCRWithVisionKit_h */

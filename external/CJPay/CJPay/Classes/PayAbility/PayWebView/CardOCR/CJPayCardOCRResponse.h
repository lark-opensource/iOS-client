//
//  CJPayCardOCRResponse.h
//  CJPay
//
//  Created by 尚怀军 on 2020/5/18.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCardOCRResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *cardNoStr;
@property (nonatomic, copy) NSString *croppedImgStr;

@end

NS_ASSUME_NONNULL_END

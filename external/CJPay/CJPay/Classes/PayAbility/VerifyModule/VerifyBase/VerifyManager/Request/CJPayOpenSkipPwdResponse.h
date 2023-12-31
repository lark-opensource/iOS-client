//
//  CJPayOpenSkipPwdResponse.h
//  Pods
//
//  Created by 尚怀军 on 2021/3/11.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayOpenSkipPwdResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *openResultStr;
@property (nonatomic, copy) NSString *buttonText;

@end

NS_ASSUME_NONNULL_END

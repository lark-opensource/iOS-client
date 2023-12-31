//
//  CJPayECUpgrateSkipPwdResponse.h
//  Pods
//
//  Created by 孟源 on 2021/10/13.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayECUpgrateSkipPwdResponse : CJPayBaseResponse
@property (nonatomic, copy) NSString *modifyResult;
@property (nonatomic, copy) NSString *buttonText;
@end

NS_ASSUME_NONNULL_END

//
//  BDTuring+SMSCode.h
//  BDTuring
//
//  Created by bob on 2021/8/5.
//

#import "BDTuring.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringSendCodeModel, BDTuringCheckCodeModel;

@interface BDTuring (SMSCode)

- (void)sendCodeWithModel:(BDTuringSendCodeModel *)model;
- (void)checkCodeWithModel:(BDTuringCheckCodeModel *)model;

@end

NS_ASSUME_NONNULL_END

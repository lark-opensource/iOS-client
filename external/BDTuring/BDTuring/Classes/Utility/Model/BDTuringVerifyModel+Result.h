//
//  BDTuringVerifyModel+Result.h
//  BDTuring
//
//  Created by bob on 2020/7/9.
//

#import "BDTuringVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringVerifyResult;

@interface BDTuringVerifyModel (Result)

- (void)handleResultStatus:(BDTuringVerifyStatus)status;

@end

NS_ASSUME_NONNULL_END

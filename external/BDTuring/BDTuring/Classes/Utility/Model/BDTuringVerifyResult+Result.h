//
//  BDTuringVerifyResult+Result.h
//  BDTuring
//
//  Created by bob on 2020/7/9.
//

#import "BDTuringVerifyResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringVerifyResult (Result)

@property (nonatomic, assign) BDTuringVerifyStatus status;
/// token or mobile might be null if request model is not sms
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *mobile;

@end

NS_ASSUME_NONNULL_END

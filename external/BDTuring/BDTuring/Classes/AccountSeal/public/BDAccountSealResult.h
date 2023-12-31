//
//  BDAccountSealResult.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyResult.h"
#import "BDAccountSealDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAccountSealResult : BDTuringVerifyResult

/*
 you should use this code for SealResult, not status
 */
@property (nonatomic, assign, readonly) BDAccountSealResultCode resultCode;

/// those properties just in case you want it
@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, copy, nullable, readonly) NSString *message;
@property (nonatomic, copy, nullable, readonly) NSDictionary *extraData;

+ (instancetype)unsupportResult;
+ (instancetype)conflictResult;

@end

NS_ASSUME_NONNULL_END

//
//  BDTuringVerifyResult.h
//  BDTuring
//
//  Created by bob on 2020/7/9.
//

#import "BDTuringDefine.h"

NS_ASSUME_NONNULL_BEGIN

/*
 model to hold the verify result
 */
@interface BDTuringVerifyResult : NSObject

@property (nonatomic, assign, readonly) BDTuringVerifyStatus status;

/// token or mobile might be null if request model is not sms
@property (nonatomic, copy, nullable, readonly) NSString *token;
@property (nonatomic, copy, nullable, readonly) NSString *mobile;

+ (instancetype)unsupportResult;
+ (instancetype)conflictResult;
+ (instancetype)okResult;
+ (instancetype)failResult;

@end

NS_ASSUME_NONNULL_END

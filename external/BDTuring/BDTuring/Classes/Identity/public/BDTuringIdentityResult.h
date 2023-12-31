//
//  BDTuringIdentityResult.h
//  BDTuring
//
//  Created by bob on 2020/6/30.
//

#import "BDTuringVerifyResult.h"
#import "BDTuringIdentityDefine.h"

NS_ASSUME_NONNULL_BEGIN

/*
 the result model, must set it
 */
@interface BDTuringIdentityResult : BDTuringVerifyResult

/*
you should use these codes for IdentityResult, not status
*/
@property (nonatomic, assign) BDTuringIdentityCode identityAuthCode;
@property (nonatomic, assign) BDTuringIdentityCode livingDetectCode;

/// those properties just in case you want it
@property (nonatomic, assign) NSInteger serverCode;
@property (nonatomic, copy, nullable) NSString *message;
@property (nonatomic, copy) NSString *ticket;

+ (instancetype)unsupportResult;
+ (instancetype)conflictResult;

@end

NS_ASSUME_NONNULL_END

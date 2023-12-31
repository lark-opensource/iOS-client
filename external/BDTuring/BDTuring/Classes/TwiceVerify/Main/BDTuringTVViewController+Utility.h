//
//  BDTuringTVViewController+Utility.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/12/8.
//

#import "BDTuringTVViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringTVViewController (Utility)

- (void)dismissSelfControllerWithParams:(NSDictionary *)parmas error:(NSError *)error;

- (NSError *)createErrorWithErrorCode:(NSInteger)errorCode errorMsg:(NSString *)errorMsg;

- (void)showLoading;
- (void)dismissLoading;

@end

NS_ASSUME_NONNULL_END

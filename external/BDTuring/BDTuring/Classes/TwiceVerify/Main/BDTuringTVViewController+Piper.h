//
//  BDTuringTVViewController+Piper.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/12/8.
//

#import "BDTuringTVViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringTVViewController (Piper)

- (void)registerClose;
- (void)registerFetch;
- (void)registerToast;
- (void)registerShowLoading;
- (void)registerDismissLoading;
- (void)registerIsSmsAvailable;
- (void)registerOpenSms;
- (void)registerCopy;
- (void)registerAppInfo;

@end

NS_ASSUME_NONNULL_END

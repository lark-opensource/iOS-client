//
//  DouyinOpenSDKServiceCenter+Auth.h
//  DouyinOpenPlatformSDK
//
//  Created by admin on 2020/7/30.
//

#import "DouyinOpenSDKServiceCenter.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DouyinOpenSDKServiceCenter (Auth)

- (BOOL)sendAuthRequest:(DouyinOpenSDKBaseRequest*)req webFirst:(BOOL)webFirst viewController:(UIViewController*)viewController completeBlock:(DouyinOpenSDKRequestCompletedBlock)completed;


@end

NS_ASSUME_NONNULL_END

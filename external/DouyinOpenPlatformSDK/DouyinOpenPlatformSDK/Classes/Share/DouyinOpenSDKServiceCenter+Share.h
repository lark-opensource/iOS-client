//
//  DouyinOpenSDKServiceCenter+Share.h
//  DouyinOpenPlatformSDK
//
//  Created by admin on 2020/7/30.
//

#import "DouyinOpenSDKServiceCenter.h"
#import "DouyinOpenSDKShare.h"

NS_ASSUME_NONNULL_BEGIN

@interface DouyinOpenSDKServiceCenter (Share)

- (BOOL)sendRequest:(DouyinOpenSDKShareRequest *)req completeBlock:(DouyinOpenSDKRequestCompletedBlock) completed;

@end

NS_ASSUME_NONNULL_END

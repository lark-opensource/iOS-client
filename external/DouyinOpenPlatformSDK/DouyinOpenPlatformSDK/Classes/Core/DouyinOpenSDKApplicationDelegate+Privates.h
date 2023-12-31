//
//  DouyinOpenPlatformApplicationDelegate+Privates.h
//
//
//  Created by Spiker on 2019/7/8.
//

#import "DouyinOpenSDKObjects.h"
#import "DouyinOpenSDKApplicationDelegate.h"

typedef NS_ENUM(NSInteger, DouyinOpenPlatformLogLevel) {
    DouyinOpenSDKLogError = 0,
    DouyinOpenSDKLogWarning,
    DouyinOpenSDKLogDebug, 
    DouyinOpenSDKLogInfo,
};

NS_ASSUME_NONNULL_BEGIN

@class DouyinOpenSDKBaseRequest;

@interface DouyinOpenSDKApplicationDelegate (Privates)

@property (nonatomic, copy  ) NSString *apptype2appId;
@property (nonatomic, strong) NSDictionary <NSString *, NSObject *> *openPlatformInfo;

// 自定义参数
@property (nonatomic, copy  ) NSSet *customConsumerAppIds;
@property (nonatomic, copy) NSSet *customshareUrls;

- (void)onLog:(DouyinOpenPlatformLogLevel)level Info:(NSString *)s,...;

NS_ASSUME_NONNULL_END
@end


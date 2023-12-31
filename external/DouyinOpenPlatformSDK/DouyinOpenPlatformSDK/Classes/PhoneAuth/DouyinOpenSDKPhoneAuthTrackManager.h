//
//  DouyinOpenSDKPhoneAuthTrackManager.h
//  DouyinOpenPlatformSDK-6252ab7f-DYOpenPhone
//
//  Created by ByteDance on 2023/6/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DouyinOpenSDKPhoneAuthTrackManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *commonTrackerParams;
@property (nonatomic, assign) BOOL useHalf;

- (void)trackEvent:(NSString *_Nonnull)eventName extraParams:(NSDictionary *_Nullable)params;

- (void)initCommonParams;

@end

NS_ASSUME_NONNULL_END

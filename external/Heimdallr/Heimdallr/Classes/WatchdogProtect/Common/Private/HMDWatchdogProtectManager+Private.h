//
//	HMDWatchdogProtectManager+Private.h
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/9/14. 
//

#import "HMDWPCapture.h"
#import "HMDWatchdogProtectDetectProtocol.h"
#import "HMDWatchdogProtectManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDWatchdogProtectManager (Private)

- (NSDictionary *)getLocalTypes;

@property(atomic, weak)id<HMDWatchdogProtectDetectProtocol> delegate;

@end

NS_ASSUME_NONNULL_END

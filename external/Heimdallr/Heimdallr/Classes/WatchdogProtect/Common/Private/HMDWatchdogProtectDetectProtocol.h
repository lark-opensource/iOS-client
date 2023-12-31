//
//  HMDWatchdogProtectDetectProtocol.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/8.
//

#import <Foundation/Foundation.h>
#import "HMDWPCapture.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HMDWatchdogProtectDetectProtocol <NSObject>
@required
- (void)didProtectWatchdogWithCapture:(HMDWPCapture *)capture;
@end

NS_ASSUME_NONNULL_END

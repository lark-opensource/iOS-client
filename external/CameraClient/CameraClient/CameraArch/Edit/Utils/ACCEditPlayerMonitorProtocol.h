//
//  ACCEditPlayerMonitorProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2020/9/11.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditPlayerMonitorProtocol <ACCEditWrapper>

- (void)inspectAssetIfNeeded;

@end

NS_ASSUME_NONNULL_END

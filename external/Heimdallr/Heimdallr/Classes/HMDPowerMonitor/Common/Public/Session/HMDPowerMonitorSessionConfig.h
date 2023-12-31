//
//  BDPowerLogSessionConfig.h
//  LarkMonitor
//
//  Created by ByteDance on 2022/12/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDPowerMonitorSessionConfig : NSObject<NSCopying>

@property(nonatomic, assign) BOOL autoUpload; //default YES

@property(nonatomic, assign) BOOL uploadWhenAppStateChanged; //default YES

@property(nonatomic, assign) BOOL ignoreBackground; //default YES

@property(nonatomic, assign) BOOL uploadWithExtraData; //default NO

@property(nonatomic, assign) int dataCollectInterval; //default 20s, range [5,60]

@end

NS_ASSUME_NONNULL_END

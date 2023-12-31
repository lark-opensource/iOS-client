//
//  BDPowerLogConfig.h
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/29.
//

#import <Foundation/Foundation.h>
#import "BDPowerLogHighPowerConfig.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogConfig : NSObject<NSCopying>

@property (nonatomic,assign) BOOL enableNetMonitor;

@property (nonatomic,assign) BOOL enableURLSessionMetrics;

@property (nonatomic,assign) BOOL enableSceneUpdateSession;

@property (nonatomic,assign) BOOL enableWebKitMonitor;

@property (nonatomic,assign) int sceneUpdateSessionMinTime; //sec

@property (nonatomic,assign) BOOL ignoreSceneUpdateBackgroundSession;

@property (nonatomic,copy, nullable) BDPowerLogHighPowerConfig *highpowerConfig;

@property (nonatomic,copy, nullable) NSDictionary *subsceneConfig;

@end

NS_ASSUME_NONNULL_END

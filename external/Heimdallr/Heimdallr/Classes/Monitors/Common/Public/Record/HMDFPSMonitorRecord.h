//
//  HMDFPSMonitorRecord.h
//  Heimdallr
//
//  Created by joy on 2018/6/13.
//

#import <Foundation/Foundation.h>
#import "HMDMonitorRecord.h"

@interface HMDFPSMonitorRecord : HMDMonitorRecord

@property (nonatomic, assign) HMDMonitorRecordValue fps;
@property (nonatomic, assign) BOOL sceneInSwitch; // 是否处于切换态
@property (nonatomic, assign) BOOL isScrolling;
@property (nonatomic, assign) BOOL isLowPowerMode; // 是否处于低电量模式
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSNumber *> *fpsExtralValue;
@property (nonatomic, assign) NSUInteger refreshRate;

@end

//
//  HMDSmartNetTrafficMonitor.h
//  Heimdallr
//
//  Created by 王佳乐 on 2019/1/20.
//

#import <Foundation/Foundation.h>
#import "HMDMonitor.h"
#import <UIKit/UIKit.h>

extern NSString * _Nullable const kHMDSmartNetTrafficMonitor;

@interface HMDSmartNetTrafficMonitorConfig : HMDMonitorConfig
@property (nonatomic, assign) double netThreshold;
@end

@interface HMDSmartNetTrafficMonitor : HMDMonitor

@end

//
//  TMAPluginTracker.h
//  Timor
//
//  Created by muhuai on 2018/3/11.
//

#import <Foundation/Foundation.h>
#import "BDPPluginBase.h"

extern NSString *const kMonitorReportPlatformTea;
extern NSString *const kMonitorReportPlatformTeaSlardar;
extern NSString *const kMonitorReportPlatformSlardar;

@interface TMAPluginTracker : BDPPluginBase

BDP_HANDLER(reportTimeline)
BDP_HANDLER(postErrors) 

@end

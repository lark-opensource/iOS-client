//
//  OPMonitorReportPlatform.h
//  LarkOPInterface
//
//  Created by qsc on 2021/1/12.
//

#ifndef OPMonitorReportPlatform_h
#define OPMonitorReportPlatform_h
//#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, OPMonitorReportPlatform) {
    OPMonitorReportPlatformUnknown = 0,
    OPMonitorReportPlatformSlardar = 1 << 0,
    OPMonitorReportPlatformTea = 1 << 1,
};


#endif /* OPMonitorReportPlatform_h */

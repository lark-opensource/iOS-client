//
//  HMDMetricKitDiagnosticRecord.h
//  Pods
//
//  Created by ByteDance on 2023/6/11.
//

#import "HMDTrackerRecord.h"

#ifndef HMDMetricKitDiagnosticRecord_h
#define HMDMetricKitDiagnosticRecord_h

enum HMDMetricKitEventType {
    HMDMetricKitEventTypeDiagnostic,
    HMDMetricKitEventTypeMetric
};

@interface HMDMetricKitRecord : HMDTrackerRecord

@property(nonatomic, assign) enum HMDMetricKitEventType eventType;

@property(nonatomic, strong, nullable) NSDictionary* diagnostic;

@property(nonatomic, strong, nullable) NSDictionary* binaryImages;

@property(nonatomic, strong, nullable) NSDictionary* recentAppImages;

@property(nonatomic, strong, nullable) NSDictionary* historyAppImageInfo;

@property(nonatomic, strong, nullable) NSDictionary* historyPreAppImageInfo;

@property(nonatomic, strong, nullable) NSDictionary* metric;

@end


#endif /* HMDMetricKitDiagnosticRecord_h */

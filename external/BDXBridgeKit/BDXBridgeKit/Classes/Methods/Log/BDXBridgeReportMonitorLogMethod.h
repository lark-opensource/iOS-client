//
//  BDXBridgeReportMonitorLogMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/30.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeReportMonitorLogMethod : BDXBridgeMethod

@end

@interface BDXBridgeReportMonitorLogMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *logType;
@property (nonatomic, copy) NSString *service;
@property (nonatomic, strong) NSNumber *status;
@property (nonatomic, copy) NSDictionary *value;

@end

NS_ASSUME_NONNULL_END

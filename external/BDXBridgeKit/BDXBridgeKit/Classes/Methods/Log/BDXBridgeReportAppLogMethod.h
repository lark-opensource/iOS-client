//
//  BDXBridgeReportAppLogMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/28.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeReportAppLogMethod : BDXBridgeMethod

@end

@interface BDXBridgeReportAppLogMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSDictionary *params;

@end

NS_ASSUME_NONNULL_END

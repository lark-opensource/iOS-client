//
//  BDXBridgeReportADLogMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/28.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeReportADLogMethod : BDXBridgeMethod

@end

@interface BDXBridgeReportADLogMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *refer;
@property (nonatomic, copy) NSString *groupID;
@property (nonatomic, copy) NSString *creativeID;
@property (nonatomic, copy) NSString *logExtra;
@property (nonatomic, copy) NSDictionary *extraParams;

@end

NS_ASSUME_NONNULL_END

//
//  BDXBridgeReportALogMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/11.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeReportALogMethod : BDXBridgeMethod

@end

@interface BDXBridgeReportALogMethodParamCodePositionModel : BDXBridgeModel

@property (nonatomic, copy) NSString *file;
@property (nonatomic, copy) NSString *function;
@property (nonatomic, strong) NSNumber *line;

@end

@interface BDXBridgeReportALogMethodParamModel : BDXBridgeModel

@property (nonatomic, assign) BDXBridgeLogLevel level;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, strong) BDXBridgeReportALogMethodParamCodePositionModel *codePosition;

@end

NS_ASSUME_NONNULL_END

//
//  BDXBridgeRequestMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/28.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeRequestMethod : BDXBridgeMethod

@end

@interface BDXBridgeRequestMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, copy) NSDictionary *header;
@property (nonatomic, strong) id body;

@end

@interface BDXBridgeRequestMethodResultModel : BDXBridgeModel

@property (nonatomic, strong) NSNumber *httpCode;
@property (nonatomic, copy) NSDictionary *header;
@property (nonatomic, copy) NSDictionary *response;

@end

NS_ASSUME_NONNULL_END

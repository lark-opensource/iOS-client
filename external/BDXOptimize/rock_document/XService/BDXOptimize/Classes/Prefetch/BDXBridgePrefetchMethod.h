//
//  BDXBridgePrefetchMethod.h
//  BDXBridgeKit
//
//  Created by David on 2021/4/22.
//

#import <BDXBridgeKit/BDXBridgeMethod.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgePrefetchMethod : BDXBridgeMethod

@end

@interface BDXBridgePrefetchMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, copy) NSDictionary *header;
@property (nonatomic, strong) id body;

@end

@interface BDXBridgePrefetchMethodResultModel : BDXBridgeModel

@property (nonatomic, strong) NSNumber *cached;// 0: 调用之后降级走fetch 1: 取自pending中的数据 2: 取自缓存
@property (nonatomic, copy) NSDictionary *raw;// 失败的情况下 raw为空

@end

NS_ASSUME_NONNULL_END

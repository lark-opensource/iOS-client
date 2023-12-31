//
//  BDXBridgeGetMethodListMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeGetMethodListMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"

@implementation BDXBridgeGetMethodListMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeGetMethodListMethod);

- (void)callWithParamModel:(BDXBridgeGetMethodListMethodResultModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    NSMutableDictionary<NSString *, NSDictionary *> *methodList = [NSMutableDictionary dictionary];
    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
    NSDictionary<NSString *, BDXBridgeMethod *> *methods = [container.bdx_bridge mergedMethodsForEngineType:container.bdx_engineType];
    [methods enumerateKeysAndObjectsUsingBlock:^(NSString *key, BDXBridgeMethod *obj, BOOL *stop) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"authType"] = [self stringifyAuthType:obj.authType];
        methodList[key] = dict;
    }];
    BDXBridgeGetMethodListMethodResultModel *result = [BDXBridgeGetMethodListMethodResultModel new];
    result.methodList = [methodList copy];
    bdx_invoke_block(completionHandler, result, nil);
}

- (NSString *)stringifyAuthType:(BDXBridgeAuthType)authType
{
    switch (authType) {
        case BDXBridgeAuthTypePublic: return @"public";
        case BDXBridgeAuthTypeProtected: return @"protected";
        case BDXBridgeAuthTypePrivate: return @"private";
        case BDXBridgeAuthTypeSecure: return @"secure";
        default: return @"unknown";
    }
}

@end

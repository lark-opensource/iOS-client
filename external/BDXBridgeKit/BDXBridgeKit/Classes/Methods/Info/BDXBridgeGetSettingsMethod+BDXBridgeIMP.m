//
//  BDXBridgeGetSettingsMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/18.
//

#import "BDXBridgeGetSettingsMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeGetSettingsMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeGetSettingsMethod);

- (void)callWithParamModel:(BDXBridgeGetSettingsMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeInfoServiceProtocol> infoService = bdx_get_service(BDXBridgeInfoServiceProtocol);
    bdx_complete_if_not_implemented([infoService respondsToSelector:@selector(settingForKeyPath:)]);
    
    __block NSString *description = nil;
    __block BDXBridgeStatusCode statusCode = BDXBridgeStatusCodeSucceeded;
    BDXBridgeGetSettingsMethodResultModel *resultModel = nil;
    if (paramModel.keys.count > 0) {
        NSMutableDictionary<NSString *, id> *resultSettings = [NSMutableDictionary dictionary];
        [paramModel.keys enumerateObjectsUsingBlock:^(BDXBridgeGetSettingsMethodParamKeyModel *obj, NSUInteger idx, BOOL *stop) {
            id value = [infoService settingForKeyPath:obj.key];
            Class valueClass = [self classForType:obj.type];
            if (!valueClass) {
                statusCode = BDXBridgeStatusCodeInvalidParameter;
                description = [NSString stringWithFormat:@"Type: %@ is unknown.", obj.type];
                *stop = YES;
            } else if (!obj.key) {
                statusCode = BDXBridgeStatusCodeInvalidParameter;
                description = @"The key is empty.";
                *stop = YES;
            } else {
                resultSettings[obj.key] = [value isKindOfClass:valueClass] ? value : [NSNull null];
            }
        }];

        if (statusCode == BDXBridgeStatusCodeSucceeded) {
            resultModel = [BDXBridgeGetSettingsMethodResultModel new];
            resultModel.settings = [resultSettings copy];
        }
    } else {
        statusCode = BDXBridgeStatusCodeInvalidParameter;
        description = @"There should be at least one key to be specified.";
    }
    
    BDXBridgeStatus *status = statusCode == BDXBridgeStatusCodeSucceeded ? nil : [BDXBridgeStatus statusWithStatusCode:statusCode message:description];
    bdx_invoke_block(completionHandler, resultModel, status);
}

- (Class)classForType:(NSString *)type
{
    if ([type isEqualToString:@"string"]) {
        return NSString.class;
    } else if ([type isEqualToString:@"object"]) {
        return NSDictionary.class;
    } else if ([type isEqualToString:@"array"]) {
        return NSArray.class;
    } else if ([type isEqualToString:@"number"] || [type isEqualToString:@"bool"]) {
        return NSNumber.class;
    } else {
        return nil;
    }
}

@end

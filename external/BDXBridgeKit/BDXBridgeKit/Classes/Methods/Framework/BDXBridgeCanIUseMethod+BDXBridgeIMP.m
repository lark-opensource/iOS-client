//
//  BDXBridgeCanIUseMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeCanIUseMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeContainerProtocol.h"
#import <objc/runtime.h>

@implementation BDXBridgeCanIUseMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeCanIUseMethod);

- (void)callWithParamModel:(BDXBridgeCanIUseMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (paramModel.method.length == 0) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The method name should not be empty."];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }
    
    BDXBridgeCanIUseMethodResultModel *resultModel = [BDXBridgeCanIUseMethodResultModel new];
    id<BDXBridgeContainerProtocol> container = self.context[BDXBridgeContextContainerKey];
    NSDictionary<NSString *, BDXBridgeMethod *> *methods = [container.bdx_bridge mergedMethodsForEngineType:container.bdx_engineType];
    BDXBridgeMethod *method = methods[paramModel.method];
    if (method) {
        resultModel.params = [self propertiesForModelClass:method.paramModelClass];
        resultModel.results = [self propertiesForModelClass:method.resultModelClass];
        resultModel.isAvailable = YES;
    } else {
        resultModel.isAvailable = NO;
    }
    bdx_invoke_block(completionHandler, resultModel, nil);
}

- (NSArray<NSString *> *)propertiesForModelClass:(Class)modelClass
{
    if (!modelClass) {
        return nil;
    }
    
    NSMutableArray<NSString *> *properties = [NSMutableArray array];
    unsigned int count = 0;
    objc_property_t *propertyList = class_copyPropertyList(modelClass, &count);
    for (NSUInteger i = 0; i < count; ++i) {
        NSString *property = [NSString stringWithUTF8String:property_getName(propertyList[i])];
        [properties addObject:property];
    }
    free(propertyList);
    return [properties copy];
}

@end

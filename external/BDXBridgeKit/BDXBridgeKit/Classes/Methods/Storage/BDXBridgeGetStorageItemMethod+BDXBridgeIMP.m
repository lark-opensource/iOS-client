//
//  BDXBridgeGetStorageItemMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeGetStorageItemMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeStorageManager.h"

@implementation BDXBridgeGetStorageItemMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeGetStorageItemMethod);

- (void)callWithParamModel:(BDXBridgeGetStorageItemMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (paramModel.key.length == 0) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The key should not be empty."];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }
    
    BDXBridgeGetStorageItemMethodResultModel *resultModel = [BDXBridgeGetStorageItemMethodResultModel new];
    resultModel.data = [BDXBridgeStorageManager.sharedManager objectForKey:paramModel.key] ?: [NSNull null];
    bdx_invoke_block(completionHandler, resultModel, nil);
}

@end

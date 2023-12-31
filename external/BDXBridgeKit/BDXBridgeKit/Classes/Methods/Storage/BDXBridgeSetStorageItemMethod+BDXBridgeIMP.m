//
//  BDXBridgeSetStorageItemMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeSetStorageItemMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeStorageManager.h"

@implementation BDXBridgeSetStorageItemMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeSetStorageItemMethod);

- (void)callWithParamModel:(BDXBridgeSetStorageItemMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    if (paramModel.key.length == 0) {
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The key should not be empty."];
        bdx_invoke_block(completionHandler, nil, status);
        return;
    }
    
    [BDXBridgeStorageManager.sharedManager setObject:paramModel.data forKey:paramModel.key];
    bdx_invoke_block(completionHandler, nil, nil);
}

@end

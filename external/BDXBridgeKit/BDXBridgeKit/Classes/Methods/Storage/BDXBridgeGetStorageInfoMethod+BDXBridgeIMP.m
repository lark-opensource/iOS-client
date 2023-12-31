//
//  BDXBridgeGetStorageInfoMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeGetStorageInfoMethod+BDXBridgeIMP.h"
#import "BDXBridgeStorageManager.h"
#import "BDXBridge+Internal.h"

@implementation BDXBridgeGetStorageInfoMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeGetStorageInfoMethod);

- (void)callWithParamModel:(BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    BDXBridgeGetStorageInfoResultModel *resultModel = [BDXBridgeGetStorageInfoResultModel new];
    resultModel.keys = [BDXBridgeStorageManager.sharedManager allKeys];
    bdx_invoke_block(completionHandler, resultModel, nil);
}

@end

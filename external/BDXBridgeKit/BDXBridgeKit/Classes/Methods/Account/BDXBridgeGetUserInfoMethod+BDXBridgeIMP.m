//
//  BDXBridgeGetUserInfoMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/17.
//

#import "BDXBridgeGetUserInfoMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"

@implementation BDXBridgeGetUserInfoMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeGetUserInfoMethod);

- (void)callWithParamModel:(BDXBridgeModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeAccountServiceProtocol> accountService = bdx_get_service(BDXBridgeAccountServiceProtocol);
    bdx_complete_if_not_implemented(accountService);

    BDXBridgeGetUserInfoMethodResultModel *resultModel = [BDXBridgeGetUserInfoMethodResultModel new];
    if ([accountService respondsToSelector:@selector(hasLoggedIn)]) {
        resultModel.hasLoggedIn = [accountService hasLoggedIn];
    }
    if (resultModel.hasLoggedIn) {
        BDXBridgeGetUserInfoMethodResultUserInfoModel *userInfo = [BDXBridgeGetUserInfoMethodResultUserInfoModel new];
        if ([accountService respondsToSelector:@selector(userID)]) {
            userInfo.userID = [accountService userID];
        }
        if ([accountService respondsToSelector:@selector(secureUserID)]) {
            userInfo.secUserID = [accountService secureUserID];
        }
        if ([accountService respondsToSelector:@selector(uniqueID)]) {
            userInfo.uniqueID = [accountService uniqueID];
        }
        if ([accountService respondsToSelector:@selector(nickname)]) {
            userInfo.nickname = [accountService nickname];
        }
        if ([accountService respondsToSelector:@selector(avatarURLString)]) {
            userInfo.avatarURL = [accountService avatarURLString];
        }
        if ([accountService respondsToSelector:@selector(boundPhone)]) {
            userInfo.hasBoundPhone = [accountService boundPhone].length > 0;
        }
        resultModel.userInfo = userInfo;
    }
    bdx_invoke_block(completionHandler, resultModel, nil);
}

@end

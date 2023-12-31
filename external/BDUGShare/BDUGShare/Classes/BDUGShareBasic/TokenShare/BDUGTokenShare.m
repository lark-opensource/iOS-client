//
//  BDUGTokenShare.m
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import "BDUGTokenShare.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import "BDUGTokenShareModel.h"
#import "BDUGTokenShareDialogManager.h"
#import <Gaia/GAIAEngine.h>
#import "BDUGShareMacros.h"
#import "BDUGShareActivityActionManager.h"
#import "BDUGShareError.h"

static NSDictionary *lastRequestDict = nil;

#pragma mark - BDUGTokenShareInfo
@implementation BDUGTokenShareInfo

@end


@interface BDUGTokenShare () <BDUGShareActivityActionProtocol>

@property(nonatomic, strong) BDUGTokenShareInfo *shareInfo;

@end

@implementation BDUGTokenShare

GAIA_FUNCTION(BDUGShareInitializeGaiaKey)() {
    [BDUGShareActivityActionManager setTokenShareDelegate:[BDUGTokenShare class]];
}

#pragma mark - BDUGShareActivityActionProtocol

+ (BOOL)canShareWithContentItem:(BDUGShareBaseContentItem *)contentItem itemModel:(BDUGShareDataItemModel *)itemModel {
    return [BDUGTokenShare isAvailable] && [itemModel.tokenInfo tokenInfoValide];
}

+ (void)shareWithActivity:(id<BDUGActivityProtocol>)activity itemModel:(BDUGShareDataItemModel *)itemModel openThirdPlatformBlock:(BDUGShareOpenThirPlatform)openThirdPlatformBlock completion:(BDUGActivityCompletionHandler)completion {
    BDUGShareBaseContentItem *contentItem = (BDUGShareBaseContentItem *)activity.contentItem;
    BDUGTokenShareInfo *shareInfo = [[BDUGTokenShareInfo alloc] init];
    shareInfo.groupID = contentItem.groupID;
    shareInfo.shareUrl = contentItem.webPageUrl;
    shareInfo.tokenDesc = itemModel.tokenInfo.token;
    shareInfo.tokenTips = itemModel.tokenInfo.tip;
    shareInfo.tokenTitle = itemModel.tokenInfo.title;
    shareInfo.platformString = [activity activityType];
    shareInfo.channelStringForEvent = itemModel.channel;
    shareInfo.panelId = [activity panelId];
    shareInfo.panelType = contentItem.panelType;
    shareInfo.dialogDidShowBlock = activity.tokenDialogDidShowBlock;
    shareInfo.clientExtraData = contentItem.clientExtraData;
    shareInfo.completeBlock = ^(BDUGTokenShareStatusCode statusCode, NSString *desc) {
        NSError *error;
        if (statusCode == BDUGTokenShareStatusCodeSuccess) {
            !completion ?: completion(activity, nil, nil);
        } else if (statusCode == BDUGTokenShareStatusCodeUserCancel) {
            error = [BDUGShareError errorWithDomain:@"BDUGTokenShare" code:BDUGShareErrorTypeUserCancel userInfo:nil];
            !completion ?: completion(activity, error, desc);
        } else {
            error = [BDUGShareError errorWithDomain:@"BDUGTokenShare" code:BDUGShareErrorTypeOther userInfo:nil];
            !completion ?: completion(activity, error, desc);
        }
    };
    shareInfo.openThirdPlatformBlock = openThirdPlatformBlock;
    [BDUGTokenShare shareTokenWithInfo:shareInfo];
}

+ (void)setLastToken:(NSString *)token {
    [BDUGTokenShareDialogManager setLastToken:token];
}

#pragma mark - token

+ (BOOL)isAvailable {
//    if ([UIDevice btd_isPadDevice]) {
//        return NO;
//    }
    return YES;
}

+ (void)shareTokenWithInfo:(BDUGTokenShareInfo *)info {
    BDUGTokenShare *share = [[BDUGTokenShare alloc] initWithTokenInfo:info];
    [share showTokenDialog];
}

- (instancetype)initWithTokenInfo:(BDUGTokenShareInfo *)info{
    if (self = [super init]) {
        _shareInfo = info;
    }
    return self;
}

- (void)showTokenDialog {
    [BDUGTokenShareDialogManager invokeTokenShareDialogBlock:self.shareInfo];
    if (_shareInfo.dialogDidShowBlock) {
        _shareInfo.dialogDidShowBlock();
    }
}

@end

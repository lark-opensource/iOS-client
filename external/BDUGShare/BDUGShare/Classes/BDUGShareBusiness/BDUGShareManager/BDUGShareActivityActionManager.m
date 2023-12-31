//
//  BDUGShareActivityActionManager.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/15.
//

#import "BDUGShareActivityActionManager.h"
#import "BDUGShareBaseContentItem.h"
#import "BDUGSystemShare.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareError.h"
#import "BDUGShareBaseUtil.h"

@implementation BDUGShareActivityActionManager

Class <BDUGShareActivityActionProtocol> imageShareDelegate;
Class <BDUGShareActivityActionProtocol> tokenShareDelegate;

//todo：1、从activity中拆出。 2、使用装饰者模式decorator到各个activity中。

+ (BOOL)performShareWithActivity:(id <BDUGActivityProtocol>)activity
                       itemModel:(BDUGShareDataItemModel *)itemModel
          openThirdPlatformBlock:(BDUGShareOpenThirPlatform)openThirdPlatformBlock
              activityTypeString:(NSString *)activityTypeString
                      completion:(BDUGActivityCompletionHandler)completion
{
    BDUGShareBaseContentItem *contentItem = (BDUGShareBaseContentItem *)activity.contentItem;
    contentItem.serverDataModel = itemModel;
    BOOL hitUGStrategy = NO;
    if (itemModel.shareMethod == BDUGShareMethodSystem) {
        [BDUGSystemShare shareWithTitle:contentItem.title image:contentItem.image?:contentItem.thumbImage url:[NSURL URLWithString:contentItem.webPageUrl] completion:^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
            if ([activityType isEqualToString:activityTypeString]) {
                !completion ?: completion(activity, nil, nil);
            } else {
                NSError *error = [BDUGShareError errorWithDomain:@"BDUGShareSystem" code:BDUGShareErrorTypeUserCancel userInfo:nil];
                !completion ?: completion(activity, error, nil);
            }
        }];
        hitUGStrategy = YES;
    } else if (itemModel.shareMethod == BDUGShareMethodImage) {
        if ([self delegateValidated:imageShareDelegate] &&
            [imageShareDelegate canShareWithContentItem:contentItem itemModel:itemModel]) {
            [imageShareDelegate shareWithActivity:activity itemModel:itemModel openThirdPlatformBlock:openThirdPlatformBlock completion:completion];
            hitUGStrategy = YES;
        } else {
            NSString *errorString = @"图片口令分享不可用，请检查：1、subspec中是否引入BDUGImageShare。\
            2、分享数据中是否有image或者imageURL。3、share_strategy/v1/info接口是否下发口令数据";
            BDUGLoggerInfo(errorString);
            BGUGSHAREASSERT(YES, @"%@", errorString);
        }
    } else if (itemModel.shareMethod == BDUGShareMethodToken) {
        if ([self delegateValidated:tokenShareDelegate] &&
            [tokenShareDelegate canShareWithContentItem:contentItem itemModel:itemModel]) {
            [tokenShareDelegate shareWithActivity:activity itemModel:itemModel openThirdPlatformBlock:openThirdPlatformBlock completion:completion];
            hitUGStrategy = YES;
        } else {
            NSString *errorString = @"文字口令分享不可用，请检查：1、subspec中是否引入BDUGTokenShare。\
            2、share_strategy/v1/info接口是否下发口令数据";
            BDUGLoggerInfo(errorString);
            BGUGSHAREASSERT(YES, @"%@", errorString);
        }
    } else if (itemModel.shareMethod == BDUGShareMethodVideo && [contentItem videoShareValid]) {
        BDUGVideoImageShareInfo *shareInfo = [[BDUGVideoImageShareInfo alloc] init];
        shareInfo.panelID = activity.panelId;
        shareInfo.panelType = contentItem.panelType;
        shareInfo.resourceID = contentItem.groupID;
        shareInfo.resourceURLString = contentItem.videoURL;
        shareInfo.platformString = [activity contentTitle];
        shareInfo.channelStringForEvent = itemModel.channel;
        shareInfo.sandboxPath = contentItem.resourceSandboxPathString;
        shareInfo.openThirdPlatformBlock = openThirdPlatformBlock;
        shareInfo.needPreviewDialog = YES;
        shareInfo.clientExtraData = contentItem.clientExtraData;
        shareInfo.completeBlock = ^(BDUGVideoShareStatusCode statusCode, NSString *desc, BDUGVideoImageShareContentModel *resultModel) {
            NSError *error;
            if (statusCode == BDUGVideoShareStatusCodeSuccess) {
                !completion ?: completion(activity, nil, nil);
            } else {
                error = [BDUGShareError errorWithDomain:@"BDUGImageShare" code:BDUGShareErrorTypeOther userInfo:nil];
                !completion ?: completion(activity, error, desc);
            }
        };
        [BDUGVideoImageShare shareVideoWithInfo:shareInfo];
        hitUGStrategy = YES;
    }
    return hitUGStrategy;
}

+ (void)convertInfo:(BDUGVideoImageShareInfo *)info contentItem:(BDUGShareBaseContentItem *)contentItem
{
    info.channelStringForEvent = contentItem.channelString;
    info.panelType = contentItem.panelType;
    info.resourceID = contentItem.groupID;
}

#pragma mark - config delegate

+ (void)setImageShareDelegate:(Class <BDUGShareActivityActionProtocol>)delegate {
    imageShareDelegate = delegate;
}

+ (void)setTokenShareDelegate:(Class <BDUGShareActivityActionProtocol>)delegate {
    tokenShareDelegate = delegate;
}

+ (BOOL)delegateValidated:(Class <BDUGShareActivityActionProtocol>)delegate {
    return delegate && [delegate respondsToSelector:@selector(canShareWithContentItem:itemModel:)] && [delegate respondsToSelector:@selector(shareWithActivity:itemModel:openThirdPlatformBlock:completion:)];
}

#pragma mark - adapter

+ (void)setLastToken:(NSString *)token {
    if ([tokenShareDelegate respondsToSelector:@selector(setLastToken:)]) {
        [tokenShareDelegate setLastToken:token];
    }
}

@end

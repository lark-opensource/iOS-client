//
//  BDUGTokenShare.m
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import "BDUGImageShare.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDUGImageShareModel.h"
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import "BDUGImageMarkAdapter.h"
#import "BDUGShareEvent.h"
#import <BDWebImage/BDWebImageManager.h>
#import <Gaia/GAIAEngine.h>
#import "BDUGShareMacros.h"
#import "BDUGShareActivityActionManager.h"
#import "BDUGShareError.h"

#pragma mark - BDUGImageShareInfo

@implementation BDUGImageShareInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        //默认是yes
        _writeToken = YES;
    }
    return self;
}

@end


@interface BDUGImageShare () <BDUGShareActivityActionProtocol>

@property(nonatomic, strong) BDUGImageShareInfo *shareInfo;

@end

@implementation BDUGImageShare

GAIA_FUNCTION(BDUGShareInitializeGaiaKey)() {
    [BDUGShareActivityActionManager setImageShareDelegate:[BDUGImageShare class]];
}

+ (BOOL)canShareWithContentItem:(BDUGShareBaseContentItem *)contentItem itemModel:(BDUGShareDataItemModel *)itemModel {
    return [BDUGImageShare isAvailable] && [contentItem imageShareValid] && itemModel.tokenInfo.token.length > 0;
}

+ (void)shareWithActivity:(id<BDUGActivityProtocol>)activity itemModel:(BDUGShareDataItemModel *)itemModel openThirdPlatformBlock:(BDUGShareOpenThirPlatform)openThirdPlatformBlock completion:(BDUGActivityCompletionHandler)completion {
    BDUGShareBaseContentItem *contentItem = (BDUGShareBaseContentItem *)activity.contentItem;

    BDUGImageShareInfo *shareInfo = [[BDUGImageShareInfo alloc] init];
    shareInfo.image = contentItem.image;
    shareInfo.imageUrl = contentItem.imageUrl;
    shareInfo.groupID = contentItem.groupID;
    shareInfo.panelID = [activity panelId];
    shareInfo.panelType = contentItem.panelType;
    shareInfo.imageTokenDesc = itemModel.tokenInfo.token;
    shareInfo.imageTokenTips = itemModel.tokenInfo.tip;
    shareInfo.imageTokenTitle = itemModel.tokenInfo.title;
    shareInfo.channelStringForEvent = itemModel.channel;
    shareInfo.clientExtraData = contentItem.clientExtraData;
    shareInfo.completeBlock = ^(BDUGImageShareStatusCode statusCode, NSString *desc) {
        NSError *error;
        if (statusCode == BDUGImageShareStatusCodeSuccess) {
            !completion ?: completion(activity, nil, nil);
        } else if (statusCode == BDUGImageShareStatusCodeUserCancel) {
            error = [BDUGShareError errorWithDomain:@"BDUGImageShare" code:BDUGShareErrorTypeUserCancel userInfo:nil];
            !completion ?: completion(activity, error, desc);
        } else {
            error = [BDUGShareError errorWithDomain:@"BDUGImageShare" code:BDUGShareErrorTypeOther userInfo:nil];
            !completion ?: completion(activity, error, desc);
        }
    };
    shareInfo.openThirdPlatformBlock = openThirdPlatformBlock;
    [BDUGImageShare shareImageWithInfo:shareInfo];
}

+ (BOOL)isAvailable {
//    if ([UIDevice btd_isPadDevice]) {
//        return NO;
//    }
    return YES;
}

+ (void)shareImageWithInfo:(BDUGImageShareInfo *)info {
    BDUGImageShare *share = [[BDUGImageShare alloc] initWithTokenInfo:info];
    [share writeMarkToImageFromSDK];
}

- (instancetype)initWithTokenInfo:(BDUGImageShareInfo *)info{
    if (self = [super init]) {
        _shareInfo = info;
    }
    return self;
}

- (void)writeMarkToImageFromSDK {
//    [TTIndicatorView showWithIndicatorStyle:TTIndicatorViewStyleWaitingView indicatorText:@"加载中..." indicatorImage:nil autoDismiss:NO dismissHandler:nil];
    
//写入image， 看需不需要这个indicator
//    [TTIndicatorView dismissIndicators];
    if (self.shareInfo.image == nil && self.shareInfo.imageUrl.length == 0) {
        !self.shareInfo.completeBlock ?: self.shareInfo.completeBlock(BDUGImageShareStatusCodeGetImageFailed, @"没有可用分享图片");
        return;
    }
    //todo: 检查leak。嵌套问题。
    void (^writeMarkBlock)(UIImage *, NSString *) = ^(UIImage *image, NSString *imageMark) {
        if (!self.shareInfo.writeToken) {
            //不写隐码，直接往下走了。
            BDUGImageShareContentModel *contentModel = [[BDUGImageShareContentModel alloc] init];
            contentModel.image = image;
            contentModel.originShareInfo = self.shareInfo;
            [self showImagePreviewDialog:contentModel];
            return ;
        }
        [BDUGImageMarkAdapter asyncMarkImage:image withInfoString:imageMark completion:^(NSInteger errCode, NSString *errTip, UIImage *resultImage) {
            //必然主线程回调。
            NSString *condition = @"failed";
            BOOL succeed = (errCode == 0);
            if (succeed) {
                BDUGImageShareContentModel *contentModel = [[BDUGImageShareContentModel alloc] init];
                contentModel.image = resultImage;
                contentModel.originShareInfo = self.shareInfo;
                [self showImagePreviewDialog:contentModel];
                condition = @"success";
            } else {
                self.shareInfo.completeBlock(BDUGImageShareStatusCodeGetImageFailed, @"获取隐写图片失败");
            }
            [BDUGShareEventManager event:kShareHiddenInterfaceWrite params:@{
                @"channel_type" : (self.shareInfo.channelStringForEvent ?: @""),
                @"share_type" : @"image",
                @"condition" : condition,
                @"panel_type" : (self.shareInfo.panelType ?: @""),
                @"panel_id" : (self.shareInfo.panelID ?: @""),
                @"resource_id" : (self.shareInfo.groupID ?: @""),
                @"hidden_str" : (imageMark ?: @""),
            }];
            [BDUGShareEventManager trackService:kShareMonitorHiddenmarkWrite attributes:@{@"status" : @((succeed ? 0 : 1))}];
        }];
    };
    //图片隐写，以imageURL为优先级最高。
    if (self.shareInfo.imageUrl.length > 0) {
        [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:self.shareInfo.imageUrl] options:BDImageRequestDefaultPriority complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL downloadSucceed = (image != nil);
                if (!downloadSucceed) {
                    self.shareInfo.completeBlock(BDUGImageShareStatusCodeGetImageFailed, @"下载图片失败");
                } else {
                    writeMarkBlock(image, self.shareInfo.imageTokenDesc);
                }
                [BDUGShareEventManager trackService:kShareMonitorImageDownload
                                   metric:nil
                                 category:@{@"status" : (downloadSucceed ? @(0) : @(1)),
                                            @"url" : self.shareInfo.imageUrl
                                 }
                                    extra:nil];
            });
        }];
    } else {
        writeMarkBlock(self.shareInfo.image, self.shareInfo.imageTokenDesc);
    }
}

- (void)showImagePreviewDialog:(BDUGImageShareContentModel *)contentModel {
    [BDUGImageShareDialogManager invokeImageShareDialogBlock:contentModel];
    if (_shareInfo.dialogDidShowBlock) {
        _shareInfo.dialogDidShowBlock();
    }
}

@end

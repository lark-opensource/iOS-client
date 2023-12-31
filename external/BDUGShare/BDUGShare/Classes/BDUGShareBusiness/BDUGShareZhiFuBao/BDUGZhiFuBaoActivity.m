//
//  BDUGZhiFuBaoActivity.m
//  Pods
//
//  Created by 王霖 on 6/12/16.
//
//

#import "BDUGZhiFuBaoActivity.h"
#import "BDUGAliShare.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareError.h"

NSString * const BDUGActivityTypePostToZhiFuBao = @"com.BDUG.UIKit.activity.PostToZhiFuBao";

@interface BDUGZhiFuBaoActivity () <TTAliShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGZhiFuBaoActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)contentItemType {
    return BDUGActivityContentItemTypeZhiFuBao;
}

- (NSString *)activityType {
    return BDUGActivityTypePostToZhiFuBao;
}

- (NSString *)contentTitle
{
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"支付宝好友";
    }
}

- (NSString *)activityImageName
{
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareAliResource.bundle/aliplay_allshare";
    }
}

- (NSString *)shareLabel
{
    return @"share_zhifubao";
}

- (BOOL)appInstalled
{
    return [[BDUGAliShare sharedAliShare] isAvailable];
}

- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGZhiFuBaoContentItem *)contentItem;
    [self performActivityWithCompletion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if (onComplete) {
            onComplete(activity, error, desc);
        }
    }];
}

- (void)performActivityWithCompletion:(BDUGActivityCompletionHandler)completion
{
    void (^performBlock)(void) = ^{
        if (self.dataSource &&
            [self.dataSource respondsToSelector:@selector(acticity:waitUntilDataIsReady:)])  {
            __weak typeof(self)weakSelf = self;
            //todo： 测试leak。FBLeak。
            [self.dataSource acticity:self waitUntilDataIsReady:^(BDUGShareDataItemModel *item) {
                [weakSelf beginShareActionWithItemModel:item];
            }];
        } else {
            //走兜底策略。
            [self beginShareActionWithItemModel:nil];
        }
    };
    self.completion = completion;
    if ([[BDUGShareAdapterSetting sharedService] shouldBlockShareWithActivity:self]) {
        [[BDUGShareAdapterSetting sharedService] didBlockShareWithActivity:self continueBlock:performBlock];
    } else {
        performBlock();
    }
}

- (void)beginShareActionWithItemModel:(BDUGShareDataItemModel *)itemModel
{
    [[BDUGShareAdapterSetting sharedService] activityWillSharedWith:self];
    [BDUGAliShare sharedAliShare].delegate = self;
    
    BDUGZhiFuBaoContentItem *zhifubaoItem = self.contentItem;
    
    switch (zhifubaoItem.defaultShareType) {
        case BDUGShareText: {
            [[BDUGAliShare sharedAliShare] sendTextToScene:APSceneSession withText:zhifubaoItem.title customCallbackUserInfo:zhifubaoItem.callbackUserInfo];
        }
            break;
        case BDUGShareImage: {
            if (zhifubaoItem.imageUrl) {
                [[BDUGAliShare sharedAliShare] sendImageToScene:APSceneSession withImageURL:zhifubaoItem.imageUrl customCallbackUserInfo:zhifubaoItem.callbackUserInfo];

            } else {
                [[BDUGAliShare sharedAliShare] sendImageToScene:APSceneSession withImage:zhifubaoItem.image customCallbackUserInfo:zhifubaoItem.callbackUserInfo];
            }
        }
            break;
        case BDUGShareWebPage: {
            [[BDUGAliShare sharedAliShare] sendWebpageToScene:APSceneSession withWebpageURL:zhifubaoItem.webPageUrl thumbnailImage:zhifubaoItem.thumbImage thumbnailImageURL:zhifubaoItem.imageUrl title:zhifubaoItem.title description:zhifubaoItem.desc customCallbackUserInfo:zhifubaoItem.callbackUserInfo];
        }
            break;
        case BDUGShareVideo:{
            [[BDUGAliShare sharedAliShare] sendWebpageToScene:APSceneSession withWebpageURL:zhifubaoItem.videoURL thumbnailImage:zhifubaoItem.thumbImage thumbnailImageURL:zhifubaoItem.imageUrl title:zhifubaoItem.title description:zhifubaoItem.desc customCallbackUserInfo:zhifubaoItem.callbackUserInfo];
        }
            break;
        default:{
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGAliShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self aliShare:nil sharedWithError:error customCallbackUserInfo:nil];
        }
            break;
    }
}

#pragma mark - TTAliShareDelegate

- (void)aliShare:(BDUGAliShare *)aliShare sharedWithError:(NSError *)error customCallbackUserInfo:(NSDictionary *)customCallbackUserInfo {
    NSString *desc = @"分享成功";
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装支付宝", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的支付宝版本过低，无法支持分享", nil);
                break;
            default:
                desc = NSLocalizedString(@"分享失败", nil);
                break;
        }
    } else {
    }
    
    if (self.completion) {
        self.completion(self, error, desc);
    }
    
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end

//
//  TTShareMYActivity.m
//  TTShareService
//
//  Created by chenjianneng on 2019/3/15.
//

#import "BDUGToutiaoActivity.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareError.h"
#import "BDUGToutiaoShare.h"
#import "BDUGShareActivityActionManager.h"

NSString *const BDUGActivityTypeShareToutiao = @"com.BDUG.UIKit.activity.ShareToutiao";

@interface BDUGToutiaoActivity() <BDUGToutiaoShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGToutiaoActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)activityType {
    return BDUGActivityTypeShareToutiao;
}

- (NSString *)contentItemType {
    return BDUGActivityContentItemTypeShareToutiao;
}

- (NSString *)contentTitle {
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"头条";
    }
}

- (NSString *)activityImageName {
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareToutiaoResource.bundle/toutiao_allshare";
    }
}


- (NSString *)shareLabel
{
    return @"toutiao";
}

- (BOOL)appInstalled
{
    return [[BDUGToutiaoShare sharedInstance] isAvailable];
}

#pragma mark - Action

- (void)shareWithContentItem:(id<BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGToutiaoContentItem *)contentItem;
    [self performActivityWithCompletion:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if (onComplete) {
            onComplete(activity, error, desc);
        }
    }];
}

-(void)performActivityWithCompletion:(BDUGActivityCompletionHandler)completion
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

- (void)beginShareActionWithItemModel:(BDUGShareDataItemModel *)itemModel {
    [[BDUGShareAdapterSetting sharedService] activityWillSharedWith:self];
    
    BDUGToutiaoShare *toutiaoShare = [BDUGToutiaoShare sharedInstance];
    toutiaoShare.delegate = self;
    
    BDUGToutiaoContentItem *contentItem = [self contentItem];
    switch (contentItem.defaultShareType) {
        case BDUGShareWebPage: {
            [toutiaoShare sendWebpage:contentItem.webPageUrl title:contentItem.title imageURL:contentItem.imageUrl isVideo:NO];
        }
            break;
        case BDUGShareText: {
            [toutiaoShare sendImage:nil title:contentItem.title postExtra:contentItem.postExtra];
        }
            break;
        case BDUGShareImage: {
            [toutiaoShare sendImage:contentItem.image title:contentItem.title postExtra:contentItem.postExtra];
        }
            break;
        case BDUGShareVideo: {
            [toutiaoShare sendWebpage:contentItem.webPageUrl title:contentItem.title imageURL:contentItem.imageUrl isVideo:YES];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGToutiaoShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self toutiaoShare:nil sharedWithError:error];
        }
            break;
    }
}

- (void)toutiaoShare:(BDUGToutiaoShare *)toutiaoShare sharedWithError:(NSError *)error; {
    NSString *desc = nil;
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装头条", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的头条版本过低，无法支持分享", nil);
                break;
            case BDUGShareErrorTypeExceedMaxTitleSize:
            case BDUGShareErrorTypeExceedMaxWebPageURLSize:
                desc = NSLocalizedString(@"文本过长，暂不支持分享", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportShareType:
                desc = NSLocalizedString(@"暂不支持的分享类型", nil);
                break;
            default:
                desc = NSLocalizedString(@"分享失败", nil);
                break;
        }
    } else {
        desc = NSLocalizedString(@"分享成功", nil);
    }

    if (self.completion) {
        self.completion(self, error, desc);
    }
    [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:self error:error desc:desc];
}

@end

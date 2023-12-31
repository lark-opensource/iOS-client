//
//  TTShareMYActivity.m
//  TTShareService
//
//  Created by chenjianneng on 2019/3/15.
//

#import "BDUGMayaActivity.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareError.h"
#import "BDUGMayaShare.h"
#import "BDUGShareActivityActionManager.h"

NSString *const BDUGActivityTypeShareMaya = @"com.BDUG.UIKit.activity.ShareMaya";

@interface BDUGMayaActivity() <BDUGMayaShareDelegate>

@property (nonatomic,copy) BDUGActivityCompletionHandler completion;

@end

@implementation BDUGMayaActivity

@synthesize dataSource = _dataSource, panelId = _panelId;

- (NSString *)activityType {
    return BDUGActivityTypeShareMaya;
}

- (NSString *)contentItemType {
    return BDUGActivityContentItemTypeShareMaya;
}

- (NSString *)contentTitle {
    if ([self.contentItem respondsToSelector:@selector(contentTitle)] && [self.contentItem contentTitle]) {
        return [self.contentItem contentTitle];
    } else {
        return @"多闪";
    }
}

- (NSString *)activityImageName {
    if ([self.contentItem respondsToSelector:@selector(activityImageName)] && [self.contentItem activityImageName]) {
        return [self.contentItem activityImageName];
    } else {
        return @"BDUGShareMayaResource.bundle/maya_allshare";
    }
}


- (NSString *)shareLabel
{
    return @"maya";
}

- (BOOL)appInstalled
{
    return [[BDUGMayaShare sharedMYShare] isAvailable];
}

#pragma mark - Action

- (void)shareWithContentItem:(id<BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController onComplete:(BDUGActivityCompletionHandler)onComplete
{
    self.contentItem = (BDUGMayaContentItem *)contentItem;
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
    
    [BDUGMayaShare sharedMYShare].delegate = self;
    
    BDUGMayaContentItem *contentItem = [self contentItem];
    switch (contentItem.defaultShareType) {
        case BDUGShareWebPage: {
            [[BDUGMayaShare sharedMYShare] sendWebpageToScene:MYSceneIM withWebpageURL:contentItem.webPageUrl thumbnailImage:contentItem.thumbImage title:contentItem.title description:contentItem.desc];
        }
            break;
        default: {
            NSString *desc = @"暂不支持的分享类型";
            NSError *error = [BDUGShareError errorWithDomain:BDUGMayaShareErrorDomain code:BDUGShareErrorTypeAppNotSupportShareType userInfo:@{NSLocalizedDescriptionKey:desc}];
            [self mayaShare:nil sharedWithError:error];
        }
            break;
    }
}

- (void)mayaShare:(BDUGMayaShare *)mayaShare sharedWithError:(NSError *)error; {
    NSString *desc = nil;
    if (error) {
        switch (error.code) {
            case BDUGShareErrorTypeAppNotInstalled:
                desc = NSLocalizedString(@"您未安装多闪", nil);
                break;
            case BDUGShareErrorTypeAppNotSupportAPI:
                desc = NSLocalizedString(@"您的多闪版本过低，无法支持分享", nil);
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

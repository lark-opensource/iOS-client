//
//  ACCRepoQuickStoryModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/11/30.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CallBackT)(id result);
typedef NSString * ACCLandingTabKey;
FOUNDATION_EXPORT ACCLandingTabKey const ACCLandingTabKeyKaraoke;

@interface ACCRepoQuickStoryModel : NSObject

@property (nonatomic, strong) void (^beforeEditPublish)(CallBackT done); // 在发布前提交业务数据，如新签名、新背景、新头像等
@property (nonatomic, assign) BOOL isQuickStory;
@property (nonatomic, assign) BOOL isQuickShootTarget;

@property (nonatomic, assign, readonly) BOOL isNewcomersStory; // 新人视频
@property (nonatomic, assign, readonly) BOOL isAvatarQuickStory; // 换头像发日常
@property (nonatomic, assign, readonly) BOOL isProfileBgStory; // 换背景发日常
@property (nonatomic, assign) BOOL isAvatarDirectPush; // 换头像静默发布
@property (nonatomic, assign) BOOL isNewCityStory; //换城市发日常

@property (nonatomic, assign) BOOL isQuickShootChangeIcon; // 是否快拍加号异化
@property (nonatomic, copy) ACCLandingTabKey initialTab;
@property (nonatomic, assign) NSInteger newMention;
@property (nonatomic, assign) NSInteger displayHashtagSticker;

@property (nonatomic, assign) NSInteger hasPaint;

@property (nonatomic, copy) NSString *friendsFeedPostPromotionType;

- (BOOL)shouldBuildQuickStoryPanel;

- (BOOL)shouldDisableQuickPublishActionSheet;

#pragma mark - story 待删除

@property (nonatomic, copy) NSString *videoCode;            //用于stroy的md5

@property (nonatomic, assign) BOOL saveStoryToLocal;

@end

@interface AWEVideoPublishViewModel (RepoQuickStory)
 
@property (nonatomic, strong, readonly) ACCRepoQuickStoryModel *repoQuickStory;

@end

NS_ASSUME_NONNULL_END

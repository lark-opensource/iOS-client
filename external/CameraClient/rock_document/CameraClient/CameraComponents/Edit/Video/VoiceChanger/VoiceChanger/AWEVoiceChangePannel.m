//
//  AWEVoiceChangePannel.m
//  Pods
//
//  Created by chengfei xiao on 2019/5/22.
//

#import "AWERepoVoiceChangerModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVoiceChangePannel.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CameraClient/AWEEffectPlatformManager.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CreationKitArch/ACCModuleConfigProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "AWERepoVideoInfoModel.h"

ACCContextId(ACCEditChangeVoicePanelContext)

#define kAWEVoiceChangePanelPadding 6

@interface AWEVoiceChangePannel ()
@property (nonatomic, readwrite) AWEVoiceChangerSelectView *voiceSelectView;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, assign) BOOL isFectchingEffects;
@property (nonatomic, assign) BOOL indexPathHadRecovered;//面板选中变声位置恢复

@property (nonatomic, strong) id<ACCModuleConfigProtocol> moduleConfig;
@end


@implementation AWEVoiceChangePannel

IESAutoInject(ACCBaseServiceProvider(), moduleConfig, ACCModuleConfigProtocol)

- (void)dealloc
{
    ACCLog(@"%@ dealloc",self.class);
}

- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super initWithFrame:frame];
    if (self) {
        _publishModel = publishModel;
        [self setupUI];
        [self fetchVoiceList];
    }
    return self;
}

- (void)setupUI
{
    [self addSubview:self.blurView];
    CGFloat selectViewHeight = 208.f + kAWEVoiceChangePanelPadding;
    CGFloat panelViewHeight = ACC_IPHONE_X_BOTTOM_OFFSET + selectViewHeight;
    
    ACCMasMaker(self.blurView, {
        make.left.right.equalTo(self);
        make.height.equalTo(@(panelViewHeight));
        make.bottom.equalTo(self).offset(kAWEVoiceChangePanelPadding);
    });
    
    //for dismiss
    [self addSubview:self.topView];
    ACCMasMaker(self.topView, {
        make.top.left.right.equalTo(self);
        make.bottom.equalTo(self.blurView.mas_top);
    });
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToClose:)];
    [self.topView addGestureRecognizer:tapGesture];
    
    //display ui
    if (self.blurView.superview) {
        UIView *bg = [UIView new];
        bg.backgroundColor = ACCColorFromRGBA(0, 0, 0, 0.3f);
        [self.blurView.contentView addSubview:bg];
        ACCMasMaker(bg, {
            make.edges.equalTo(self.blurView);
        });
        
        [self.blurView.contentView addSubview:self.voiceSelectView];
        ACCMasMaker(self.voiceSelectView, {
            make.top.equalTo(@(0));
            make.left.equalTo(@(0));
            make.width.equalTo(@(ACC_SCREEN_WIDTH));
            make.height.equalTo(@(selectViewHeight));
        });
    }
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, panelViewHeight)
                                               byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft
                                                     cornerRadii:CGSizeMake(12, 12)];
    maskLayer.path = path.CGPath;
    self.blurView.layer.mask = maskLayer;
}

- (BOOL)hasTimeMachineEffect {
    return (self.publishModel.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineRelativity || self.publishModel.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineTimeTrap);

}

#pragma mark - fetch data

- (void)fetchVoiceList
{
    [IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) preloadInitializationEffectPlatformManager];
    
    self.isFectchingEffects = YES;
    NSString *pannel = @"voicechanger";
    NSString *category = @"all";
    //use cache ahead
    IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:pannel category:category];
    NSString *recoverID;
    if (self.publishModel.repoVoiceChanger.voiceEffectType == ACCVoiceEffectTypeWhole && !self.voiceSelectView.selectedIndexPath) {
        recoverID = self.publishModel.repoVoiceChanger.voiceChangerID;
    }
    
    if (![self.voiceSelectView.effectList count] || [cachedResponse.categoryEffects.effects count] > [self.voiceSelectView.effectList count]) {
        [self.voiceSelectView updateWithVoiceEffectList:cachedResponse.categoryEffects.effects?:@[] recoverWithVoiceID:recoverID];
    }
    
    //check update
    @weakify(self);
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [EffectPlatform checkEffectUpdateWithPanel:pannel category:category effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        if (needUpdate || ![cachedResponse.categoryEffects.effects count]) {
            [self.moduleConfig configureExtraInfoForEffectPlatform];
            [EffectPlatform downloadEffectListWithPanel:pannel category:category pageCount:0 cursor:0 sortingPosition:0 effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                             completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
                                                 @strongify(self);
                                                 self.isFectchingEffects = NO;
                                                 if (!error && response.categoryEffects.effects.count) {
                                                     acc_dispatch_main_async_safe(^{
                                                         if (self.showing) {
                                                             [self.voiceSelectView updateWithVoiceEffectList:response.categoryEffects.effects?:@[] recoverWithVoiceID:recoverID];
                                                             //之前选择了兜底的音效，拉到数据刷新UI，如果缓存的 effect 没有下载则恢复原声
                                                             IESEffectModel *recoverEffectOfLocal = [[AWEEffectPlatformManager sharedManager] localVoiceEffectWithID:self.publishModel.repoVoiceChanger.voiceChangerID];
                                                             if (recoverEffectOfLocal) {
                                                                 [cachedResponse.categoryEffects.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                                                     if ([[AWEEffectPlatformManager sharedManager] equalWithCachedEffect:obj localEffect:recoverEffectOfLocal]) {
                                                                         if (!obj.downloaded) {
                                                                             ACCBLOCK_INVOKE(self.didSelectVoiceHandler, nil, nil);
                                                                         }
                                                                     }
                                                                 }];
                                                             }
                                                         }
                                                     });
                                                     [ACCMonitor() trackService:@"aweme_voice_effect_list_error"
                                                                              status:0
                                                                               extra:@{@"panel" : pannel ?: @"",
                                                                                       @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                                                                       @"needUpdate" : @(needUpdate)}];
                                                 } else {
                                                     [ACCMonitor() trackService:@"aweme_voice_effect_list_error"
                                                                              status:1
                                                                               extra:@{@"panel" : pannel ?: @"",
                                                                                       @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                                                                       @"needUpdate" : @(needUpdate),
                                                                                       @"errorDesc" : error.description ?: @"",
                                                                                       @"errorCode" : @(error.code)}];
                                                 }
                                             }];
        } else {
            self.isFectchingEffects = NO;
            [ACCMonitor() trackService:@"aweme_voice_effect_list_error"
                                     status:0
                                      extra:@{@"panel" : pannel ?: @"",
                                              @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                              @"needUpdate" : @(NO)}];
        }
    }];
}

#pragma mark - lazy load

- (UIView *)topView
{
    if (_topView == nil) {
        _topView = [UIView new];
        _topView.backgroundColor = [UIColor clearColor];
        //accessibility
        _topView.isAccessibilityElement = YES;
        _topView.accessibilityLabel = @"关闭变声面板";
        _topView.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitStaticText;
    }
    return _topView;
}

- (UIVisualEffectView *)blurView
{
    if (_blurView == nil) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _blurView.clipsToBounds = YES;
    }
    return _blurView;
}

- (AWEVoiceChangerSelectView *)voiceSelectView
{
    if (_voiceSelectView == nil) {
        _voiceSelectView = [[AWEVoiceChangerSelectView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT) publishModel:self.publishModel];
        @weakify(self);
        self.voiceSelectView.didSelectVoiceEffectHandler = ^(IESEffectModel * _Nonnull voiceEffect, NSError * _Nonnull error) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.didSelectVoiceHandler, voiceEffect, error);
        };
        self.voiceSelectView.didTapVoiceEffectHandler = ^(IESEffectModel * _Nonnull voiceEffect, NSError * _Nonnull error) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.didTapVoiceHandler, voiceEffect, error);
        };
        self.voiceSelectView.clearVoiceEffectHandler = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.clearVoiceEffectHandler);
        };
    }
    return _voiceSelectView;
}

#pragma mark - show & dismiss logic

- (void)tapToClose:(UITapGestureRecognizer *)gesture
{
    ACCBLOCK_INVOKE(self.dismissHandler);
}

- (void)pannelDidShow
{
    if (self.publishModel.repoVoiceChanger.voiceChangerID && !self.indexPathHadRecovered) {
        self.indexPathHadRecovered = YES;
        if (self.voiceSelectView.selectedIndexPath.row >= 4) {
            [self.voiceSelectView.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                                           atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                                                   animated:YES];
            [self.voiceSelectView.collectionView scrollToItemAtIndexPath:self.voiceSelectView.selectedIndexPath
                                                                           atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                                                   animated:YES];
        }
    }
    [self.voiceSelectView reloadData];
    self.showing = YES;
    NSString *pannel = @"voicechanger";
    NSString *category = @"all";
    IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:pannel category:category];
    if ((cachedResponse.categoryEffects.effects.count && self.voiceSelectView.effectList.count) &&
        (cachedResponse.categoryEffects.effects.count > self.voiceSelectView.effectList.count)) {//列表展示的是兜底，现在拉到了数据，刷新列表
        [self.voiceSelectView updateWithVoiceEffectList:cachedResponse.categoryEffects.effects?:@[] recoverWithVoiceID:self.publishModel.repoVoiceChanger.voiceChangerID];
        //之前选择了兜底的音效，拉到数据刷新UI，如果缓存的 effect 没有下载则恢复原声
        IESEffectModel *recoverEffectOfLocal = [[AWEEffectPlatformManager sharedManager] localVoiceEffectWithID:self.publishModel.repoVoiceChanger.voiceChangerID];
        if (recoverEffectOfLocal) {
            [cachedResponse.categoryEffects.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([[AWEEffectPlatformManager sharedManager] equalWithCachedEffect:obj localEffect:recoverEffectOfLocal]) {
                    if (!obj.downloaded) {
                        ACCBLOCK_INVOKE(self.didSelectVoiceHandler, nil, nil);
                    }
                }
            }];
        }
        
    } else if (![cachedResponse.categoryEffects.effects count] && !self.isFectchingEffects) {//没有数据重拉
        [self fetchVoiceList];
    }
}

#pragma mark - ACCPanelViewProtocol

- (void *)identifier
{
    return ACCEditChangeVoicePanelContext;
}

- (CGFloat)panelViewHeight
{
    return self.frame.size.height;
}

@end

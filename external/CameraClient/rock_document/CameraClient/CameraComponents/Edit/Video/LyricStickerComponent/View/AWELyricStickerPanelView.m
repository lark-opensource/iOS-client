//
//  AWELyricStickerPanelView.m
//  AWEStudio-Pods-Aweme
//
//  Created by Liu Deping on 2019/10/8.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWELyricStickerPanelView.h"
#import "AWELyricStyleCollectionViewCell.h"
#import "AWEStoryColorChooseView.h"
#import "AWEMusicNameInfoView.h"
#import "AWEStickerLyricStyleManager.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCKaraokeDataHelperProtocol.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

#define ContentViewHeight (162 + ACC_IPHONE_X_BOTTOM_OFFSET)
#define MusicClipViewHeight (250 + ACC_IPHONE_X_BOTTOM_OFFSET)
#define kAWELyricMusicPanelPadding 6

@interface AWELyricStickerPanelView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIView *topFunctionView;
@property (nonatomic, strong) UIView *colorChooseContainer;
@property (nonatomic, strong) UICollectionView *lyricStyleCollectionView;
@property (nonatomic, strong) AWEMusicNameInfoView *musicInfoView;
@property (nonatomic, strong) UIButton *colorButton;
@property (nonatomic, strong) UIButton *clipMusicButton;
@property (nonatomic, assign) BOOL isKaraoke;
@property (nonatomic, assign) BOOL isShowColorChoose;
@property (nonatomic, strong) AWEStoryColorChooseView *colorChooseView;
@property (nonatomic, strong) UIView *sepLine;
@property (nonatomic, copy) NSArray<IESEffectModel *> *effectModels;
@property (nonatomic, assign) BOOL firstShow;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSIndexPath *previousSelectedIndexPath;
@property (nonatomic, strong) IESEffectModel *firstEffectModel;
@property (nonatomic, copy) NSString *initialEffectId;
@property (nonatomic, strong) UIColor *initialColor;
@property (nonatomic, copy) NSString *musicId;
@property (nonatomic, strong) IESEffectModel *currentEffectModel;
@property (nonatomic, strong) UIView *seplineVisualView;

@end

@implementation AWELyricStickerPanelView

- (instancetype)initWithFrame:(CGRect)frame
               selectEffectId:(nullable NSString *)effectId
                        color:(nullable UIColor *)color
                     isKaraoke:(BOOL)isKaraoke
               viewController:(UIViewController *)viewController
{
    if (self = [super initWithFrame:frame]) {
        _initialEffectId = effectId;
        _initialColor = color;
        _viewController = viewController;
        _isKaraoke = isKaraoke;
        [self _setupViewComponents];
    }
    return self;
}

- (AWEStoryColor *)currentSelectColor
{
    return self.colorChooseView.selectedColor;
}

- (void)updateWithEffectModels:(NSArray<IESEffectModel *> *)effectModels
{
    if (!effectModels || effectModels.count <= 0) {
        return;
    }
    self.firstEffectModel = effectModels.firstObject;
    self.currentEffectModel = self.firstEffectModel;
    self.effectModels = effectModels;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    if (!ACC_isEmptyString(self.initialEffectId)) {
        [effectModels enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.effectIdentifier isEqualToString:self.initialEffectId]) {
                self.selectedIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                self.currentEffectModel = obj;
                *stop = YES;
            }
        }];
    }
    self.previousSelectedIndexPath = self.selectedIndexPath;
    acc_dispatch_main_async_safe(^{
        [self.lyricStyleCollectionView reloadData];
    });
    [self.lyricStyleCollectionView layoutIfNeeded];
    AWELyricStyleCollectionViewCell *currentCell = (AWELyricStyleCollectionViewCell *)[self.lyricStyleCollectionView cellForItemAtIndexPath:self.selectedIndexPath];
    [currentCell setIsCurrent:YES];
    [self.lyricStyleCollectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    if (self.effectModels.count > self.selectedIndexPath.row && !self.effectModels[self.selectedIndexPath.row].downloaded) {
        [self p_selectAndDownloadEffectAtIndexPath:self.selectedIndexPath];
    }
}

- (void)resetStickerPanelState
{
    if (self.effectModels.count > 0) {
        AWELyricStyleCollectionViewCell *lastSelectCell = (AWELyricStyleCollectionViewCell *)[self.lyricStyleCollectionView cellForItemAtIndexPath:self.selectedIndexPath];
        [lastSelectCell setIsCurrent:NO];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        AWELyricStyleCollectionViewCell *currentCell = (AWELyricStyleCollectionViewCell *)[self.lyricStyleCollectionView cellForItemAtIndexPath:indexPath];
        [currentCell setIsCurrent:YES];
        [self.lyricStyleCollectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self.colorChooseView.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    }
}

- (void)updateWithMusicModel:(id<ACCMusicModelProtocol>)musicModel enableClip:(BOOL)enableClip
{
    NSString *musicName = [NSString stringWithFormat:@"%@ - %@", musicModel.musicName, musicModel.authorName];
    CGSize nameSize = [musicName sizeWithAttributes:@{NSFontAttributeName : [ACCFont() systemFontOfSize:14.0f weight:ACCFontWeightMedium]}];
    self.clipMusicButton.enabled = enableClip;
    self.musicId = musicModel.musicID;
    
    ACCMasReMaker(self.musicInfoView, {
        make.leading.equalTo(self.topFunctionView.mas_leading).offset(16);
        make.trailing.lessThanOrEqualTo(self.topFunctionView.mas_trailing).offset(-120);
        make.centerY.equalTo(self.topFunctionView);
        make.height.equalTo(@(20));
        make.width.equalTo(@(nameSize.width + 30));
    });
    [self setNeedsLayout];
    [self layoutIfNeeded];
    /// @note Layout subviews before `configRollingXX`, or _musicInfoView's size would be zero.
    [_musicInfoView configRollingAnimationWithLabelString:musicName];
}

- (void)_setupViewComponents
{
    [self addSubview:self.blurView];
    ACCMasMaker(self.blurView, {
        make.leading.trailing.equalTo(self);
        make.height.equalTo(@(ContentViewHeight));
        make.top.equalTo(self.mas_bottom);
    });

    [self.blurView.contentView addSubview:self.colorChooseContainer];
    ACCMasMaker(self.colorChooseContainer, {
        make.leading.top.equalTo(self.blurView.contentView);
        make.trailing.equalTo(self.blurView.contentView.mas_trailing).offset(-64);
        make.height.equalTo(@(52));
    });
    
    [self.colorChooseContainer addSubview:self.colorChooseView];
    ACCMasMaker(self.colorChooseView, {
        make.leading.equalTo(self.colorChooseContainer.mas_trailing);
        make.top.bottom.equalTo(self.colorChooseContainer);
        make.width.equalTo(@(ACC_SCREEN_WIDTH - 64));
    });
    
    [self.blurView.contentView addSubview:self.topFunctionView];
    ACCMasMaker(self.topFunctionView, {
        make.leading.trailing.top.equalTo(self.blurView.contentView);
        make.height.equalTo(@(52));
    });
    
    [self.blurView.contentView addSubview:self.seplineVisualView];
    ACCMasMaker(self.seplineVisualView, {
        make.trailing.equalTo(self.blurView.contentView.mas_trailing);
        make.width.equalTo(@69);
        make.height.equalTo(@(52));
        make.top.equalTo(self.blurView.contentView);
    });
    
    [self.topFunctionView addSubview:self.clipMusicButton];
    ACCMasMaker(self.clipMusicButton, {
        make.trailing.equalTo(self.topFunctionView.mas_trailing).offset(-20.0f);
        make.centerY.equalTo(self.topFunctionView);
        make.size.mas_equalTo(CGSizeMake(32.0f, 32.0f));
    });
    self.clipMusicButton.hidden = self.isKaraoke;
    
    [self.blurView.contentView addSubview:self.colorButton];
    ACCMasMaker(self.colorButton, {
        make.trailing.equalTo(self.mas_trailing).offset(self.isKaraoke ? -20.f : -72.f);
        make.centerY.equalTo(self.topFunctionView);
        make.size.mas_equalTo(CGSizeMake(32.0f, 32.0f));
    });
    
    [self.topFunctionView addSubview:self.musicInfoView];
    
    [self.blurView.contentView addSubview:self.lyricStyleCollectionView];
    ACCMasMaker(self.lyricStyleCollectionView, {
        make.top.equalTo(self).offset(78);
        make.leading.trailing.equalTo(self.blurView.contentView);
        make.height.equalTo(@(75));
    });
}

- (void)didMoveToSuperview
{
    if (self.firstShow == NO) {
        self.firstShow = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self show];
        });
    }
}

- (void)show
{
    [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        ACCMasUpdate(self.blurView, {
            make.top.equalTo(self);
            make.bottom.equalTo(self).offset(kAWELyricMusicPanelPadding);
        });
        [self setNeedsLayout];
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            self.showing = YES;
            ACCBLOCK_INVOKE(self.showHandler);
        }
    }];
    
    NSDictionary *params = @{@"enter_from" : @"video_eidt_page",
                             @"creation_Id" : self.creationId ? : @"",
                             @"shoot_way" : self.shootWay ? : @"",
                             @"music_id" : self.musicId ? : @"",
    };
    [ACCTracker() trackEvent:@"edit_lyricsticker"
                                     params:params
                            needStagingFlag:NO];
}

- (void)showWithEffectId:(NSString *)effectId color:(UIColor *)color
{
    [self show];
    if (self.effectModels.count > 0) {
        __block NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.effectModels enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([effectId isEqualToString:obj.effectIdentifier]) {
                indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                *stop = YES;
            }
        }];
        if (self.selectedIndexPath.row != indexPath.row) {
            AWELyricStyleCollectionViewCell *lastCell = (AWELyricStyleCollectionViewCell *)[self.lyricStyleCollectionView cellForItemAtIndexPath:self.selectedIndexPath];
            [lastCell setIsCurrent:NO];
            AWELyricStyleCollectionViewCell *currentCell = (AWELyricStyleCollectionViewCell *)[self.lyricStyleCollectionView cellForItemAtIndexPath:indexPath];
            [currentCell setIsCurrent:YES];
            [self.lyricStyleCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            self.selectedIndexPath = indexPath;
        }
        self.currentEffectModel = self.effectModels[self.selectedIndexPath.row];
    }
    [self.colorChooseView selectWithColor:color];
}

- (void)dismiss
{
    @weakify(self);
    [self hide:^(BOOL finished) {
        @strongify(self);
        self.showing = NO;
        ACCBLOCK_INVOKE(self.dismissHandler);
        self.hidden = YES;
    }];
}

- (void)tapToClose
{
    @weakify(self);
    [self hide:^(BOOL finished) {
        @strongify(self);
        self.showing = NO;
        ACCBLOCK_INVOKE(self.dismissHandler);
        self.hidden = YES;
    }];
}

- (void)hide:(void(^)(BOOL finished))completion
{
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
      self.blurView.acc_top = self.acc_bottom;
    } completion:^(BOOL finished) {
        ACCBLOCK_INVOKE(completion, finished);
        self.showing = NO;
        [self p_hideColorChooseButton];
        self.isShowColorChoose = NO;
    }];
}

- (void)clickColorButton:(id)sender
{
    if (self.isShowColorChoose) {
        self.isShowColorChoose = NO;
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            [self p_hideColorChooseButton];
        } completion:nil];
    } else {
        self.isShowColorChoose = YES;
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.topFunctionView.hidden = YES;
            self.colorButton.acc_right = self.bounds.size.width - 22.0f;
            self.colorChooseView.acc_left = 0;
            self.colorChooseView.alpha = 1.0;
            self.seplineVisualView.hidden = NO;
        } completion:nil];
    }
}

- (void)clickClipMusicButton:(id)sender
{
    ACCBLOCK_INVOKE(self.clickClipMusicHandler);
    NSDictionary *params = @{@"creation_Id" : self.creationId ? : @"",
                             @"shoot_way" : self.shootWay ? : @"",
                             @"music_id" : self.musicId ? : @"",
                             @"dynamics" :  self.currentEffectModel.effectName ? : @""
    };
    [ACCTracker() trackEvent:@"select_lyricsticker_clip"
                                     params:params
                            needStagingFlag:NO];
}

- (void)clickMusicNameButton:(id)sender
{
    ACCBLOCK_INVOKE(self.clickMusicNameHandler);
}

- (void)p_clearSeletedCellExcept:(AWELyricStyleCollectionViewCell *)cell
{
    for (AWELyricStyleCollectionViewCell *visibleCell in [self.lyricStyleCollectionView visibleCells]) {
        if (visibleCell != cell) {
            [visibleCell setIsCurrent:NO];
        }
    }
}

-(void)p_selectAndDownloadEffectAtIndexPath:(NSIndexPath *)indexPath
{
    AWELyricStyleCollectionViewCell *cell = (AWELyricStyleCollectionViewCell *)[self.lyricStyleCollectionView cellForItemAtIndexPath:indexPath];
    IESEffectModel *model = cell.currentEffectModel;
    
    [cell showLoadingAnimation:YES];
    @weakify(self);
    @weakify(cell);
    
    __block NSError *resultError = nil;
    __block BOOL relatedSuccess = YES;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [EffectPlatform downloadEffect:model downloadQueuePriority:NSOperationQueuePriorityHigh downloadQualityOfService:NSQualityOfServiceUtility progress:^(CGFloat progress) {
        AWELogToolDebug(AWELogToolTagEdit, @"AWELyricStickerPanelView process is %.2f",progress);
    } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        resultError = error;
        dispatch_group_leave(group);
    }];
    
    if (self.isKaraoke) {
        let stickerDataHelper = [IESAutoInline(ACCBaseServiceProvider(), ACCKaraokeDataHelperProtocol) class];
        dispatch_group_enter(group);
        [stickerDataHelper fetchRelatedInfos:model completion:^(IESEffectModel *font, IESEffectModel *title, BOOL success){
            relatedSuccess = success;
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        @strongify(self);
        @strongify(cell);
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            return;
        }
        // 歌词下载成功即可，歌词信息样式容许失败也展示
        if (!resultError && model.filePath && relatedSuccess) {
            model.downloadStatus = AWEEffectDownloadStatusDownloaded;
            if (self.isKaraoke) {
                [[EffectPlatform sharedInstance] saveCacheWithEffect:model];
            }
            if (self.previousSelectedIndexPath == indexPath) {
                self.selectedIndexPath = indexPath;
                [self p_selectWithCell:cell model:model indexPath:indexPath];
            }
        } else {
            model.downloadStatus = AWEEffectDownloadStatusUndownloaded;
            [ACCToast() show:ACCLocalizedCurrentString(@"load_failed")];
            NSDictionary *params = @{@"creation_Id" : self.creationId ? : @"",
                                     @"shoot_way" : self.shootWay ? : @"",
                                     @"music_id" : self.musicId ? : @"",
                                     @"dynamics" :  model.effectName ? : @""
            };
            [ACCTracker() trackEvent:@"select_lyricsticker_dynamics"
                                             params:params
                                    needStagingFlag:NO];
            self.currentEffectModel = model;
            ACCBLOCK_INVOKE(self.selectStickerStyleHandler, model, nil, resultError);
        }
        [cell showLoadingAnimation:NO];
    });
}

- (void)p_selectWithCell:(AWELyricStyleCollectionViewCell *)cell model:(IESEffectModel *)model indexPath:(NSIndexPath *)indexPath
{
    [self p_clearSeletedCellExcept:cell];
    [cell setIsCurrent:YES];
    self.currentEffectModel = model;
    // 模型默认颜色处理
    __block NSInteger colorIndex = 0;
    __block AWEStoryColor *defaultColor = nil;
    if (model.extra != nil) {
        NSError *error = nil;
        NSDictionary *extraDic = [NSJSONSerialization JSONObjectWithData:[model.extra dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (!error && extraDic && extraDic[AWELyricStyleDefaultColorKey] != nil) {
            NSString *defaultColorStr = [extraDic acc_stringValueForKey:AWELyricStyleDefaultColorKey];
            if ([defaultColorStr hasPrefix:@"#"]) {
                defaultColorStr = [defaultColorStr substringFromIndex:1];
            }
            // 下发的字段是#ARGB 安卓用这种形式，iOS做兼容，alpha目前用不到
            if (defaultColorStr.length == 8) {
                defaultColorStr = [defaultColorStr substringFromIndex:2];
            }
            // 拼接成colorProvider的样式
            defaultColorStr = [NSString stringWithFormat:@"0x%@", defaultColorStr];
            // 匹配
            [self.colorChooseView.storyColors enumerateObjectsUsingBlock:^(AWEStoryColor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.colorString.lowercaseString isEqualToString:defaultColorStr.lowercaseString]) {
                    colorIndex = idx;
                    defaultColor = obj;
                    *stop = YES;
                }
            }];
            
        } else {
            // fix lint error
            ACC_LogError(@"json serialization error=%@|extraDic=%@", error, extraDic);
        }
    }
    
    ACCBLOCK_INVOKE(self.selectStickerStyleHandler, model, defaultColor, nil);
    
    NSIndexPath *resetIndexPath = [NSIndexPath indexPathForRow:colorIndex inSection:0];
    [self.colorChooseView updateSelectedColorWithIndexPath:resetIndexPath];
    [self.colorChooseView.collectionView selectItemAtIndexPath:resetIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    NSDictionary *params = @{@"creation_Id" : self.creationId ? : @"",
                             @"shoot_way" : self.shootWay ? : @"",
                             @"music_id" : self.musicId ? : @"",
                             @"dynamics" :  model.effectName ? : @""
    };
    [ACCTracker() trackEvent:@"select_lyricsticker_dynamics"
                                     params:params
                            needStagingFlag:NO];
}

- (void)p_hideColorChooseButton
{
    self.topFunctionView.hidden = NO;
    self.colorButton.acc_right = self.bounds.size.width - (self.isKaraoke ? 20.f : 72.f);
    self.colorChooseView.acc_left = self.colorChooseView.acc_width;
    self.colorChooseView.alpha = 0.0;
    self.seplineVisualView.hidden = YES;
}

- (void)setDisableChangeMusic:(BOOL)disableChangeMusic
{
    _disableChangeMusic = disableChangeMusic;
    self.musicInfoView.isDisableStyle = disableChangeMusic;
}

#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.effectModels.count) {
        if (self.selectedIndexPath == indexPath) {
            AWELyricStyleCollectionViewCell *cell = (AWELyricStyleCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            if (cell.isCurrent) {
                return;
            }
        }
        
        self.previousSelectedIndexPath = indexPath;
        AWELyricStyleCollectionViewCell *aCell = (AWELyricStyleCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        IESEffectModel *model = aCell.currentEffectModel;
        if (model.downloadStatus == AWEEffectDownloadStatusDownloading) {
            [self p_clearSeletedCellExcept:aCell];
            [aCell setIsCurrent:NO];
            return;
        }
        BOOL isDownload = model.downloaded;
        if (self.isKaraoke && isDownload) {
            let stickerDataHelper = [IESAutoInline(ACCBaseServiceProvider(), ACCKaraokeDataHelperProtocol) class];
            isDownload = [stickerDataHelper karaokeLyricModelValid:model];
        }
        
        if (!isDownload || model.downloadStatus == AWEEffectDownloadStatusUndownloaded) {
            model.downloadStatus = AWEEffectDownloadStatusDownloading;
            [self p_clearSeletedCellExcept:aCell];
            [aCell setIsCurrent:NO];
            [self p_selectAndDownloadEffectAtIndexPath:indexPath];
        } else {
            self.selectedIndexPath = indexPath;
            [self p_selectWithCell:aCell model:model indexPath:indexPath];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [self.effectModels count]) {
        return;
    }
    
    AWELyricStyleCollectionViewCell *aCell = (AWELyricStyleCollectionViewCell *)cell;
    if ([indexPath isEqual:self.selectedIndexPath]) {
        if (self.previousSelectedIndexPath != self.selectedIndexPath) {
            if (self.selectedIndexPath.row == 0) {
                IESEffectModel *model = [self.effectModels acc_objectAtIndex:self.previousSelectedIndexPath.row];
                if (!model.downloaded) {
                    [aCell setIsCurrent:NO];
                    return;
                }
            }
        }
        [aCell setIsCurrent:YES];
    } else {
        [aCell setIsCurrent:NO];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.effectModels.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWELyricStyleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([AWELyricStyleCollectionViewCell class]) forIndexPath:indexPath];
    if (indexPath.row < self.effectModels.count) {
        IESEffectModel *effectModel = [self.effectModels objectAtIndex:indexPath.row];
        cell.currentEffectModel = effectModel;
    }
    return cell;
}


- (UIVisualEffectView *)blurView
{
    if (!_blurView) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _blurView.clipsToBounds = YES;
        _blurView.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, ContentViewHeight);
    }
    return _blurView;
}

- (UIView *)topView
{
    if (!_topView) {
        _topView = [UIView new];
        _topView.backgroundColor = [UIColor clearColor];
    }
    return _topView;
}

- (UIView *)topFunctionView
{
    if (!_topFunctionView) {
        _topFunctionView = [[UIView alloc] init];
        _topFunctionView.backgroundColor = [UIColor clearColor];
    }
    return _topFunctionView;
}

- (AWEMusicNameInfoView *)musicInfoView
{
    if (!_musicInfoView) {
        _musicInfoView = [[AWEMusicNameInfoView alloc] init];
        [_musicInfoView addViewTapTarget:self action:@selector(clickMusicNameButton:)];
    }
    return _musicInfoView;
}

- (UIButton *)colorButton
{
    if (!_colorButton) {
        _colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_colorButton setImage:ACCResourceImage(@"ic_sticker_color") forState:UIControlStateNormal];
        [_colorButton addTarget:self action:@selector(clickColorButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _colorButton;
}

- (UIButton *)clipMusicButton
{
    if (!_clipMusicButton) {
        _clipMusicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_clipMusicButton setImage:ACCResourceImage(@"iconCameraMusicclip-1") forState:UIControlStateNormal];
        [_clipMusicButton addTarget:self action:@selector(clickClipMusicButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _clipMusicButton;
}

- (UICollectionView *)lyricStyleCollectionView
{
    if (!_lyricStyleCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(60.0f, 75.0f);
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumLineSpacing = 16.0f;
        layout.minimumInteritemSpacing = 0.0f;
        _lyricStyleCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _lyricStyleCollectionView.backgroundColor = [UIColor clearColor];
        _lyricStyleCollectionView.showsHorizontalScrollIndicator = NO;
        _lyricStyleCollectionView.contentInset = UIEdgeInsetsMake(0, 12, 0, 12);
        [_lyricStyleCollectionView registerClass:[AWELyricStyleCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([AWELyricStyleCollectionViewCell class])];
        _lyricStyleCollectionView.delegate = self;
        _lyricStyleCollectionView.dataSource = self;
        if ([_lyricStyleCollectionView respondsToSelector:@selector(contentInsetAdjustmentBehavior)]) {
            if (@available(iOS 11.0, *)) {
                _lyricStyleCollectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
    }
    return _lyricStyleCollectionView;
}

- (AWEStoryColorChooseView *)colorChooseView
{
    if (!_colorChooseView) {
        _colorChooseView = [[AWEStoryColorChooseView alloc] init];
        _colorChooseView.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 10);
        if (_initialColor) {
            [_colorChooseView selectWithColor:_initialColor];
        }
        [_colorChooseView acc_edgeFadingWithValue:5];
        @weakify(self);
        _colorChooseView.didSelectedColorBlock = ^(AWEStoryColor * _Nonnull selectColor, NSIndexPath * _Nonnull indexPath) {
            @strongify(self);
            NSDictionary *params = @{@"creation_Id" : self.creationId ? : @"",
                                     @"shoot_way" : self.shootWay ? : @"",
                                     @"music_id" : self.musicId ? : @"",
                                     @"color_id" :  selectColor.colorString ? : @""
            };
            [ACCTracker() trackEvent:@"select_lyricsticker_color"
                                             params:params
                                    needStagingFlag:NO];
            ACCBLOCK_INVOKE(self.selectColorHandler, selectColor);
        };
    }
    return _colorChooseView;
}

- (UIView *)sepLine
{
    if (!_sepLine) {
        _sepLine = [[UIView alloc] init];
        _sepLine.backgroundColor = ACCResourceColor(ACCUIColorConstLineInverse);
    }
    return _sepLine;
}

- (UIView *)colorChooseContainer
{
    if (!_colorChooseContainer) {
        _colorChooseContainer = [[UIView alloc] init];
        _colorChooseContainer.layer.masksToBounds = YES;
        _colorChooseContainer.backgroundColor = [UIColor clearColor];
    }
    return _colorChooseContainer;
}

- (UIView *)seplineVisualView
{
    if (!_seplineVisualView) {
        _seplineVisualView = [[UIView alloc] init];
        UIView *sepLineView = [[UIView alloc] initWithFrame:CGRectMake(5, 14, 0.5, 24)];
        sepLineView.backgroundColor = ACCResourceColor(ACCUIColorLineInverse);
        [_seplineVisualView addSubview:sepLineView];
        [_seplineVisualView acc_edgeFading];
        _seplineVisualView.hidden = YES;
    }
    return _seplineVisualView;
}

- (BOOL)isEmptyEffect
{
    return ACC_isEmptyArray(self.effectModels);
}

@end

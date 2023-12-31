//
//  AWESingleMusicView+Private.h
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/4/2.
//

#import "AWESingleMusicView.h"
#import <CameraClient/ACCSelectMusicViewControllerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCInsetsLabelProtocol;

@interface AWESingleMusicTitleView: UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) id<ACCInsetsLabelProtocol> songTagLabel;
@property (nonatomic, assign) BOOL isEliteVersion;

@end

@class ACCCollectionButton, AWEMusicTitleControl;

@interface AWESingleMusicView ()

@property (nonatomic, strong) UIButton *clipButton;
@property (nonatomic, strong) ACCCollectionButton *collectionButton;
@property (nonatomic, strong) AWEMusicTitleControl *applyControl;
@property (nonatomic, strong) id<ACCMusicModelProtocol> musicModel;

@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UIImageView *playView;
@property (nonatomic, strong) UIImageView *rankImageView;
@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) AWESingleMusicTitleView *songNameView;
@property (nonatomic, strong) UILabel *authorNameLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *lyricLabel;
@property (nonatomic, strong) UIImageView *recommandView;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, assign) AWESingleMusicViewLayoutStatus currentStatus;
@property (nonatomic, assign) ACCAVPlayerPlayStatus playerStatus;
@property (nonatomic, strong) UILabel  *tagLabel;
@property (nonatomic, strong) UIScrollView *tagContentView;
@property (nonatomic, strong) UIView *musicTagContentView;

@property (nonatomic, strong) UIImage *logoPlaceholderImage;
@property (nonatomic, strong) UIImage *originalMusicMusiCianIcon;

- (void)setupUI NS_REQUIRES_SUPER;
- (void)configTitleLabelWithMusicName:(NSString *)musicName;
- (void)configMusicTagContentViewWithModel:(id<ACCMusicModelProtocol>)model;
- (void)configAuthorNameLabelWithModel:(id<ACCMusicModelProtocol>)model;
- (void)configLogoViewWithModel:(id<ACCMusicModelProtocol>)model;
- (void)configDurationLabelWithModel:(id<ACCMusicModelProtocol>)model;

- (NSString *)musicUseCountString:(NSInteger)count;
- (void)transformToStatus:(AWESingleMusicViewLayoutStatus)status animated:(BOOL)animated;
- (UIColor *)lyricsLabelHighlightColor;
- (UIColor *)lyricsLabelNormalColor;
@end

NS_ASSUME_NONNULL_END

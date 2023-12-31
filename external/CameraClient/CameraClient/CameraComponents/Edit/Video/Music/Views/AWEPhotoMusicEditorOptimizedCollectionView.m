//
//  AWEPhotoMusicEditorOptimizedCollectionView.m
//  Pods
//
//  Created by resober on 2019/5/27.
//

#import "AWEPhotoMusicEditorOptimizedCollectionView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEMusicLoadingAnimationCell.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEPhotoMusicEditorOptimizedCollectionView ()
@property (nonatomic, strong) UILabel *emptyCollectionLabel;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, strong) UIImageView *loadingMoreImageView;
@property (nonatomic, strong) AWEMusicLoadingAnimationCell *animationView;
@end

@implementation AWEPhotoMusicEditorOptimizedCollectionView
@synthesize emptyCollectionLabel, loadingMoreImageView, retryBlock, firstLoadingAnimationFrame;

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.emptyCollectionLabel = [UILabel new];
    [self addSubview:self.emptyCollectionLabel];
    self.emptyCollectionLabel.hidden = YES;
    self.emptyCollectionLabel.text = ACCLocalizedString(@"com_mig_add_sound_to_favorites_to_find_or_use_it_later",@"你还没有收藏任何歌曲");
    self.emptyCollectionLabel.font = [UIFont systemFontOfSize:14];
    self.emptyCollectionLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
    self.emptyCollectionLabel.textAlignment = NSTextAlignmentCenter;
    ACCMasMaker(self.emptyCollectionLabel, {
        make.centerY.equalTo(self).offset(-16.f);
        make.centerX.equalTo(self).offset(-16.f);
        make.width.equalTo(self);
        make.height.equalTo(@(17.f));
    });

    self.retryButton = [UIButton new];
    [self addSubview:self.retryButton];
    self.retryButton.hidden = YES;
    self.retryButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.retryButton setTitleColor:ACCResourceColor(ACCUIColorTextTertiary) forState:UIControlStateNormal];
    self.retryButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.retryButton setTitle: ACCLocalizedCurrentString(@"error_retry") forState:UIControlStateNormal];
    ACCMasMaker(self.retryButton, {
        make.centerY.equalTo(self).offset(-8.f);
        make.centerX.equalTo(self).offset(-16.f);
        make.width.equalTo(self);
        make.height.equalTo(@(17.f));
    });
    [self.retryButton addTarget:self action:@selector(retryButtonClicked:) forControlEvents:UIControlEventTouchUpInside];


    self.loadingMoreImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"iconDownloadingMusic")];
    [self addSubview:self.loadingMoreImageView];
    self.loadingMoreImageView.hidden = YES;
    self.loadingMoreImageView.frame = CGRectMake(0, 28.f, 16.f, 16.f);

    self.animationView = [[AWEMusicLoadingAnimationCell alloc] initWithFrame:self.bounds];
    self.animationView.animationFillToContent = YES;
    [self addSubview:self.animationView];
    self.animationView.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.contentSize.width < self.frame.size.width) {
        self.loadingMoreImageView.hidden = YES;
    } else {
        self.loadingMoreImageView.frame = CGRectMake(self.contentSize.width + 30.f, 28.f, 16.f, 16.f);
    }
}

- (void)setFirstLoadingAnimationFrame:(CGRect)firstLoadingAnimationFrame {
    self.animationView.frame = firstLoadingAnimationFrame;
}

- (void)startLoadingMoreAnimating {
    self.loadingMoreImageView.hidden = NO;
    CABasicAnimation *animation = [[CABasicAnimation alloc] init];
    animation.keyPath = @"transform.rotation.z";
    animation.fromValue = @(0);
    animation.toValue = @(M_PI * 2);
    animation.duration = 0.9;
    animation.removedOnCompletion = NO;
    animation.repeatCount = HUGE_VALF;
    [self.loadingMoreImageView.layer addAnimation:animation forKey:animation.keyPath];
}

- (void)stopLoadingMoreAnimating {
    self.loadingMoreImageView.hidden = YES;
    [self.loadingMoreImageView.layer removeAllAnimations];
}

- (void)startFirstLoadingAnimation {
    self.animationView.hidden = NO;
    [self.animationView startAnimating];
}

- (void)stopFirstLoadingAnimation {
    self.animationView.hidden = YES;
    [self.animationView stopAnimating];
}

- (void)showRetryButton {
    self.retryButton.hidden = NO;
}

- (void)hideRetryButton {
    self.retryButton.hidden = YES;
}

- (void)retryButtonClicked:(UIButton *)sender {
    if (self.retryBlock) {
        self.retryBlock();
    }
}
@end

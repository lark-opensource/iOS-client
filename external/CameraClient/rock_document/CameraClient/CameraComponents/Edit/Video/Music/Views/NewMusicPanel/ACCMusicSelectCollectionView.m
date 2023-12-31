//
//  ACCMusicSelectCollectionView.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/7/4.
//

#import "ACCMusicSelectCollectionView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEMusicLoadingAnimationCell.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIImage+ACCAdditions.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/ACCMacros.h>


@interface ACCMusicSelectPlaceholderView : UIView

@end

@implementation ACCMusicSelectPlaceholderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        CGFloat cellHeight = 64.0;
        NSInteger cellCount = ceilf(frame.size.height / cellHeight);
        for (NSInteger index = 0; index < cellCount; index++) {
            UIView *placeViewCell = [self placeholderCell];
            [placeViewCell setFrame:CGRectMake(0, index * cellHeight, ACC_SCREEN_WIDTH, cellHeight)];
            [self addSubview:placeViewCell];
        }
    }
    return self;
}

- (UIView *)placeholderCell {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 64.f)];
    UIView *imagePlaceHolderView = [[UIView alloc] initWithFrame:CGRectMake(16, 8, 48, 48)];
    imagePlaceHolderView.layer.cornerRadius = 4;
    imagePlaceHolderView.backgroundColor = ACCResourceColor(ACCColorBGInputReverse);
    [view addSubview:imagePlaceHolderView];
    
    UIView *titlePlaceholderView = [[UIView alloc] initWithFrame:CGRectMake(80, 14, 150, 15)];
    titlePlaceholderView.layer.cornerRadius = 2;
    titlePlaceholderView.backgroundColor = ACCResourceColor(ACCColorBGInputReverse);
    [view addSubview:titlePlaceholderView];
    
    UIView *authorPlaceholderView = [[UIView alloc] initWithFrame:CGRectMake(80, 35, 80, 15)];
    authorPlaceholderView.layer.cornerRadius = 2;
    authorPlaceholderView.backgroundColor = ACCResourceColor(ACCColorBGInputReverse);
    [view addSubview:authorPlaceholderView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(80, 63.5, ACC_SCREEN_WIDTH - 80, 0.5)];
    lineView.backgroundColor = ACCResourceColor(ACCColorLineReverse2);
    [view addSubview:lineView];
    return view;
}

@end

@interface ACCMusicSelectCollectionView ()

@property (nonatomic, strong) UILabel *emptyCollectionLabel;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, strong) UIImageView *loadingMoreImageView;
@property (nonatomic, strong) AWEMusicLoadingAnimationCell *animationView;
@property (nonatomic, strong) ACCMusicSelectPlaceholderView *placeholderView;

@end

@implementation ACCMusicSelectCollectionView

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
    self.emptyCollectionLabel.text = ACCLocalizedString(@"com_mig_add_sound_to_favorites_to_find_or_use_it_later", @"你还没有收藏任何歌曲");
    self.emptyCollectionLabel.font = [UIFont systemFontOfSize:14];
    self.emptyCollectionLabel.textColor = ACCResourceColor(ACCColorTextReverse3);
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
    [self.retryButton setTitleColor:ACCResourceColor(ACCColorTextReverse3) forState:UIControlStateNormal];
    self.retryButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.retryButton setTitle: ACCLocalizedCurrentString(@"error_retry") forState:UIControlStateNormal];
    ACCMasMaker(self.retryButton, {
        make.centerY.equalTo(self).offset(-8.f);
        make.centerX.equalTo(self).offset(-16.f);
        make.width.equalTo(self);
        make.height.equalTo(@(17.f));
    });
    [self.retryButton addTarget:self action:@selector(retryButtonClicked:) forControlEvents:UIControlEventTouchUpInside];


    UIImage *darkLoadingImage = [ACCResourceImage(@"iconDownloadingMusic") acc_ImageWithTintColor:ACCResourceColor(ACCColorTextReverse2)];
    self.loadingMoreImageView = [[UIImageView alloc] initWithImage:darkLoadingImage];
    [self addSubview:self.loadingMoreImageView];
    self.loadingMoreImageView.hidden = YES;
    self.loadingMoreImageView.frame = CGRectMake((self.contentSize.width - 16)/2, 0, 16.f, 16.f);
    self.animationView = [[AWEMusicLoadingAnimationCell alloc] initWithFrame:self.bounds];
    self.animationView.animationFillToContent = YES;
    self.animationView.hidden = YES;
    [self addSubview:self.animationView];
    
    self.placeholderView = [[ACCMusicSelectPlaceholderView alloc] initWithFrame:self.bounds];
    self.placeholderView.hidden = YES;
    [self addSubview:self.placeholderView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.contentSize.height < self.frame.size.height) {
        self.loadingMoreImageView.hidden = YES;
    } else {
        self.loadingMoreImageView.frame = CGRectMake((self.contentSize.width - 16)/2, self.contentSize.height + 30.f, 16.f, 16.f);
    }
}

- (void)setFirstLoadingAnimationFrame:(CGRect)firstLoadingAnimationFrame {
    self.animationView.frame = firstLoadingAnimationFrame;
    self.placeholderView.frame = firstLoadingAnimationFrame;
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
    self.placeholderView.hidden = NO;
}

- (void)stopFirstLoadingAnimation {
    self.animationView.hidden = YES;
    [self.animationView stopAnimating];
    self.placeholderView.hidden = YES;
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

//
//  ACCMVTemplateInteractionViewController.m
//  CameraClient
//
//  Created by long.chen on 2020/3/9.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCMVTemplateInteractionViewController.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCUserProfileProtocol.h"
#import "ACCMVTemplatesFetchProtocol.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CameraClient/ACCGradientProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import "ACCLoadingAndVolumeView.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import "ACCMvAmountView.h"
#import "ACCMVPageStyleABHelper.h"

#import <CreativeKit/UIImageView+ACCAddtions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>

NSString *const ACCMVTemplateDidFavoriteNotification = @"ACCMVTemplateDidFavoriteNotification";
NSString *const ACCMVTemplateDidUnFavoriteNotification = @"ACCMVTemplateDidUnFavoriteNotification";

NSString *const ACCMVTemplateFavoriteTemplateKey = @"ACCMVTemplateFavoriteTemplateKey";

@interface ACCMVTemplateInteractionViewController ()

@property (nonatomic, strong) ACCAnimatedButton *favoriteButton;

@property (nonatomic, strong) ACCMvAmountView *usageAmountView;
@property (nonatomic, strong) ACCMvAmountView *fragmentAmountView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UILabel *authorNameLabel;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) ACCLoadingAndVolumeView *loadingView;
@property (nonatomic, strong) ACCAnimatedButton *pickResourceButton; // visible if not iPhoneX

@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL isSwitchCollecting;

@end

@implementation ACCMVTemplateInteractionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
    [self.view acc_addSingleTapRecognizerWithTarget:self action:@selector(p_handleSingleTapOnView:)];
}

- (void)p_setupUI
{
    [ACCGradient() addTopGradientViewForViewController:self
                                                  View:self.view
                                             FromColor:[UIColor colorWithWhite:0 alpha:0.5]
                                               toColor:UIColor.clearColor
                                                height:136];
    
    [ACCGradient() addBottomGradientViewForViewController:self
                                                     View:self.view
                                                FromColor:UIColor.clearColor
                                                  toColor:[UIColor colorWithWhite:0 alpha:0.8]
                                                   height:ACC_SCREEN_WIDTH * 2 / 5];
    [self.view addSubview:self.favoriteButton];
    ACCMasMaker(self.favoriteButton, {
        make.top.equalTo(self.view).offset(ACC_NAVIGATION_BAR_OFFSET + 34);
        make.right.equalTo(self.view).offset(-18);
        make.size.equalTo(@(CGSizeMake(40, 40)));
    });
    
    BOOL isIPhoneX = [UIDevice acc_isIPhoneX];
    
    if (!isIPhoneX) {
        [self.view addSubview:self.pickResourceButton];
        ACCMasMaker(self.pickResourceButton, {
            make.left.equalTo(self.view).offset(16);
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-16);
            make.height.equalTo(@44);
        });
    }
    
    [self.view addSubview:self.loadingView];
    ACCMasMaker(self.loadingView, {
        make.left.right.equalTo(self.view);
        make.height.equalTo(@(1));
        if ([UIDevice acc_isIPhoneX]) {
            make.bottom.equalTo(self.view).offset(-8);
        } else {
            make.bottom.equalTo(self.view).offset(-68);
        }
    });
    
    [self.view addSubview:self.avatarImageView];
    ACCMasMaker(self.avatarImageView, {
        make.left.equalTo(self.view).offset(16);
        make.bottom.equalTo(self.loadingView).offset(-16);
        make.size.equalTo(@(CGSizeMake(28, 28)));
    });
    
    [self.view addSubview:self.authorNameLabel];
    ACCMasMaker(self.authorNameLabel, {
        make.left.equalTo(self.avatarImageView.mas_right).offset(8);
        make.centerY.equalTo(self.avatarImageView);
        make.right.lessThanOrEqualTo(self.view).offset(-16);
    });
    
    [self.view addSubview:self.descriptionLabel];
    ACCMasMaker(self.descriptionLabel, {
        make.left.equalTo(self.view).offset(16);
        make.right.lessThanOrEqualTo(self.view).offset(-16);
        make.bottom.equalTo(self.loadingView).offset(-60);
    });
    
    [self.view addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.left.equalTo(self.descriptionLabel);
        make.right.lessThanOrEqualTo(self.view).offset(-16);
        make.bottom.equalTo(self.descriptionLabel.mas_top).offset(-8);
    });
    
    [self.view addSubview:self.usageAmountView];
    ACCMasMaker(self.usageAmountView, {
        make.left.equalTo(self.titleLabel);
        make.bottom.equalTo(self.titleLabel.mas_top).offset(-8);
    });
    
    [self.view addSubview:self.fragmentAmountView];
    ACCMasMaker(self.fragmentAmountView, {
        make.left.equalTo(self.usageAmountView.mas_right).offset(3);
        make.centerY.equalTo(self.usageAmountView);
    });
}

#pragma mark - Public

- (void)setTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
{
    _templateModel = templateModel;
    
    [self p_updateFavoriteIcon];
    
    if (templateModel.usageAmount > 0) {
        self.usageAmountView.hidden = NO;
        self.usageAmountView.text = [ACCMvAmountView usageAmountString:templateModel.usageAmount];
    } else {
        self.usageAmountView.hidden = YES;
    }
    
    if (templateModel.fragmentCount > 0) {
        self.fragmentAmountView.hidden = NO;
        self.fragmentAmountView.text = [NSString stringWithFormat:ACCLocalizedCurrentString(@"creation_mv_footages_num2"), templateModel.fragmentCount];
        if (self.usageAmountView.hidden) {
            ACCMasReMaker(self.fragmentAmountView, {
                make.left.equalTo(self.titleLabel);
                make.bottom.equalTo(self.titleLabel.mas_top).offset(-8);
            });
        } else {
            ACCMasReMaker(self.fragmentAmountView, {
                make.left.equalTo(self.usageAmountView.mas_right).offset(3);
                make.centerY.equalTo(self.usageAmountView);
            });
        }
    } else {
        self.fragmentAmountView.hidden = YES;
    }
    
    self.titleLabel.text = templateModel.title;
    if (templateModel.accTemplateType == ACCMVTemplateTypeClassic) {
        self.descriptionLabel.text = templateModel.hintLabel;
    } else {
        self.descriptionLabel.text = templateModel.desc;
    }
    
    BOOL hasAuthorInfo = templateModel.author != nil;
    self.avatarImageView.hidden = !hasAuthorInfo;
    self.authorNameLabel.hidden = !hasAuthorInfo;
    if (hasAuthorInfo) {
        [ACCWebImage() imageView:self.avatarImageView setImageWithURLArray:templateModel.author.avatarThumb.URLList placeholder:nil];

        NSString *authorName = [NSString stringWithFormat:@"@%@", templateModel.author.socialName ?: @""];
        self.authorNameLabel.text = authorName;
        self.avatarImageView.accessibilityLabel = authorName;
    }
    
    ACCMasUpdate(self.descriptionLabel, {
        make.bottom.equalTo(self.loadingView).offset((hasAuthorInfo ? -60 : -16));
    });
    
    if (_pickResourceButton) {
        [self.pickResourceButton setTitle:[ACCMVPageStyleABHelper acc_cutsameSelectHintText] forState:UIControlStateNormal];
    }
}

#pragma mark - ACCMVTemplateInteractionProtocol

- (void)playLoadingAnimation
{
    self.loadingView.isLoading = NO;
    self.loadingView.isLoading = YES;
}

- (void)stopLoadingAnimation
{
    self.loadingView.isLoading = NO;
}

#pragma mark - Actions

- (void)p_handleSingleTapOnView:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.paused) {
        [self.videoPlayDelegate playWithAnimation];
    } else {
        [self.videoPlayDelegate pauseWithAnimation];
    }
    self.paused = !self.paused;
}


- (void)p_handleFavoriteButtonClicked:(UIButton *)button
{
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
         [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
            if(success){
                [self p_origHandleFavoriteButtonClicked:button];
            }
        } withTrackerInformation:@{@"enter_from":@"video_edit_page"}];
    } else {
        [self p_origHandleFavoriteButtonClicked:button];
    }

}

- (void)p_origHandleFavoriteButtonClicked:(UIButton *)button {
    
    if (self.isSwitchCollecting) {
        return;
    }
    
    self.isSwitchCollecting = YES;
    if (self.templateModel.isCollected) {
        [ACCMVTemplatesFetch() unFavoriteMVTemplateWithID:self.templateModel.templateID
                                                 templateType:self.templateModel.accTemplateType
                                                   completion:^(NSError * error) {
            if (!error) {
                self.templateModel.isCollected = NO;
                [self p_doFavoriteIconAnimation:NO];
                [[NSNotificationCenter defaultCenter] postNotificationName:ACCMVTemplateDidUnFavoriteNotification
                                                                    object:self
                                                                  userInfo:@{
                                                                      ACCMVTemplateFavoriteTemplateKey : self.templateModel
                                                                  }];
            } else {
                if (!ACC_isEmptyString(error.localizedDescription)) {
                    [ACCToast() show:error.localizedDescription];
                }
            }
            self.isSwitchCollecting = NO;
        }];
        
        [ACCTracker() trackEvent:@"cancel_favourite_mv"
                           params:@{
                               @"mv_id" : @(self.templateModel.templateID),
                               @"enter_from" : @"mv_card",
                               @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                               @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                               @"content_type" : self.templateModel.accTemplateType == ACCMVTemplateTypeClassic ? @"mv" : @"jianying_mv",
                               @"mv_recommend" : @"1",
                           }
                  needStagingFlag:NO];
    } else {
        [ACCMVTemplatesFetch() favoriteMVTemplateWithID:self.templateModel.templateID
                                               templateType:self.templateModel.accTemplateType
                                                 completion:^(NSError * error) {
            if (!error) {
                self.templateModel.isCollected = YES;
                [self p_doFavoriteIconAnimation:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:ACCMVTemplateDidFavoriteNotification
                                                                    object:self
                                                                  userInfo:@{
                                                                      ACCMVTemplateFavoriteTemplateKey : self.templateModel
                                                                  }];
            } else {
                if (!ACC_isEmptyString(error.localizedDescription)) {
                    [ACCToast() show:error.localizedDescription];
                }
            }
            self.isSwitchCollecting = NO;
        }];
        
        [ACCTracker() trackEvent:@"favourite_mv"
                           params:@{
                               @"mv_id" : @(self.templateModel.templateID),
                               @"enter_from" : @"mv_card",
                               @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                               @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                               @"content_type" : self.templateModel.accTemplateType == ACCMVTemplateTypeClassic ? @"mv" : @"jianying_mv",
                               @"mv_recommend" : @"1",
                           }
                  needStagingFlag:NO];
    }
}

- (void)p_handlePickResourceButtonClicked:(UIButton *)button
{
    ACCBLOCK_INVOKE(self.didPickTemplateBlock, self.templateModel);
    
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.publishModel.repoTrack.referExtra];
    [referExtra addEntriesFromDictionary:@{
        @"content_type" : self.templateModel.accTemplateType == ACCMVTemplateTypeClassic ? @"mv" : @"jianying_mv",
        @"content_source" : @"upload",
        @"enter_from" : @"mv_card",
        @"mv_id" : @(self.templateModel.templateID),
        @"mv_name" : self.templateModel.title ?: @"",
        @"impr_position" : @(self.indexPath.row + 1),
        @"mv_recommend" : @"1",
    }];
    [ACCTracker() trackEvent:@"select_mv"
                       params:referExtra
              needStagingFlag:NO];
}

- (void)p_enterUserProfile:(UITapGestureRecognizer *)gestureRecognizer
{
    if (ACC_isEmptyString(self.templateModel.author.userID)) {
        return;
    }
    [IESAutoInline(ACCBaseServiceProvider(), ACCUserProfileProtocol) enterUserProfileWithUserID:self.templateModel.author.userID];
    
    NSString *clickMethod = @"click_name";
    if ([gestureRecognizer.view isKindOfClass:UIImageView.class]) {
        clickMethod = @"click_head";
    }
    [ACCTracker() track:@"enter_personal_detail"
                  params:@{
                      @"enter_from" : @"mv_card",
                      @"enter_method" : clickMethod,
                      @"to_user_id" : self.templateModel.author.userID,
                      @"creation_id" : self.publishModel.repoContext.createId ?: @"",
                      @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
                  }];
}

- (void)p_doFavoriteIconAnimation:(BOOL)favorited
{
    [self p_updateFavoriteIcon];
    [UIView animateWithDuration:0.15f
                     animations:^{
        self.favoriteButton.transform = CGAffineTransformMakeScale(0.7f, 0.7f);
        self.favoriteButton.alpha = 0.f;
    }];
    [UIView animateWithDuration:0.05f
                          delay:0.15f
                        options:0
                     animations:^{
        self.favoriteButton.transform = CGAffineTransformIdentity;
        self.favoriteButton.alpha = 1.f;
    } completion:nil];
}

- (void)p_updateFavoriteIcon
{
    if (self.templateModel.isCollected) {
        [self.favoriteButton setImage:ACCResourceImage(@"ic_mv_template_favorite_selected")
                             forState:UIControlStateNormal];
        self.favoriteButton.accessibilityLabel = @"取消收藏";
    } else {
        [self.favoriteButton setImage:ACCResourceImage(@"ic_mv_template_favorite_unselected")
                             forState:UIControlStateNormal];
        self.favoriteButton.accessibilityLabel = @"收藏";
    }
}

#pragma mark - Getters

- (ACCAnimatedButton *)favoriteButton
{
    if (!_favoriteButton) {
        _favoriteButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectZero type:ACCAnimatedButtonTypeScale];
        _favoriteButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-15, -15, -15, -15);  
        [_favoriteButton addTarget:self action:@selector(p_handleFavoriteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        _favoriteButton.isAccessibilityElement = YES;
        _favoriteButton.accessibilityLabel = @"收藏";
    }
    return _favoriteButton;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:20 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    }
    return _titleLabel;
}

- (UILabel *)descriptionLabel
{
    if (!_descriptionLabel) {
        _descriptionLabel = [UILabel new];
        _descriptionLabel.numberOfLines = 0;
        _descriptionLabel.font = [ACCFont() acc_systemFontOfSize:14];
        _descriptionLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    }
    return _descriptionLabel;
}

- (UIImageView *)avatarImageView
{
    if (!_avatarImageView) {
        _avatarImageView = [UIImageView new];
        _avatarImageView.layer.masksToBounds = YES;
        _avatarImageView.layer.cornerRadius = 14;
        _avatarImageView.isAccessibilityElement = YES;
        _avatarImageView.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, -20, -20, -20);
        [_avatarImageView acc_addSingleTapRecognizerWithTarget:self action:@selector(p_enterUserProfile:)];
    }
    return _avatarImageView;;
}

- (UILabel *)authorNameLabel
{
    if (!_authorNameLabel) {
        _authorNameLabel = [UILabel new];
        _authorNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _authorNameLabel.font = [ACCFont() acc_systemFontOfSize:14];
        _authorNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        [_authorNameLabel acc_addSingleTapRecognizerWithTarget:self action:@selector(p_enterUserProfile:)];
    }
    return _authorNameLabel;
}

- (ACCLoadingAndVolumeView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [ACCLoadingAndVolumeView new];
    }
    return _loadingView;
}

- (ACCAnimatedButton *)pickResourceButton
{
    if (!_pickResourceButton) {
        _pickResourceButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectZero type:ACCAnimatedButtonTypeAlpha];
        _pickResourceButton.backgroundColor = ACCResourceColor(ACCColorPrimary);
        _pickResourceButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        _pickResourceButton.titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _pickResourceButton.layer.masksToBounds = YES;
        _pickResourceButton.layer.cornerRadius = 2;
        _pickResourceButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-4, 0, -4, 0);
        [_pickResourceButton setImage:ACCResourceImage(@"icon_video_upload_multiple_selected") forState:UIControlStateNormal];
        [_pickResourceButton setImageEdgeInsets:UIEdgeInsetsMake(0, -4, 0, 4)];
        [_pickResourceButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, -4)];
        [_pickResourceButton addTarget:self action:@selector(p_handlePickResourceButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pickResourceButton;
}

- (ACCMvAmountView *)usageAmountView
{
    if (!_usageAmountView) {
        _usageAmountView = [[ACCMvAmountView alloc] initWithFrame:CGRectZero];
    }
    return _usageAmountView;
}

- (ACCMvAmountView *)fragmentAmountView
{
    if (!_fragmentAmountView) {
        _fragmentAmountView = [[ACCMvAmountView alloc] initWithFrame:CGRectZero];
    }
    return _fragmentAmountView;
}


@end

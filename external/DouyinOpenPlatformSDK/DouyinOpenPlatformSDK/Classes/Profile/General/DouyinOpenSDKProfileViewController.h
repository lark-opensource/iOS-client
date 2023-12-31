//
//  DouyinOpenSDKProfileViewController.h
//  DouyinOpenPlatformSDK
//
//  Created by bytedance on 2022/2/23.
//

#import <UIKit/UIKit.h>
#import "DouyinOpenSDKProfileContext.h"
#import "DouyinOpenSDKGeneralProfile.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^DouyinOpenSDKPresentProfileCompletion)(NSInteger errorCode, NSString* errorMsg);

@interface DouyinOpenSDKProfileViewController : UIViewController
@property (nonatomic, strong) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UIView *ageGenderView;
@property (nonatomic, strong) IBOutlet UILabel *uniLabel;
@property (nonatomic, strong) IBOutlet UILabel *likesLabel;
@property (nonatomic, strong) IBOutlet UILabel *followersLabel;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *videoImageViews;
@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, strong) IBOutlet UIButton *followButton;
- (IBAction)followButtonPressed:(UIButton *)sender;
@property (nonatomic, strong) IBOutlet UIButton *DYButton;
- (IBAction)DYButtonPressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *videoLikesLabels;
- (IBAction)backButtonPressed:(UIButton *)sender;
@property (nonatomic, strong) IBOutlet UIView *baseView;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *bottomLayoutGapView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *baseViewHeight;
@property (nonatomic, strong) IBOutlet UIImageView *genderImageView;
@property (nonatomic, strong) IBOutlet UILabel *ageLabel;
@property (nonatomic, strong) IBOutlet UILabel *locationLabel;
@property (nonatomic, strong) IBOutlet UIImageView *exceptionImageView;
@property (nonatomic, strong) IBOutlet UILabel *exceptionTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *exceptionDescLabel;
@property (nonatomic, strong) IBOutlet UIView *exceptionView;
@property (nonatomic, strong) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *exceptionImageViewTop;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *locationWidth;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *uniWidth;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *buttonTopSpace;
@property (nonatomic, assign) DouyinOpenSDKProfileVCType vcType;
@property (nonatomic, copy) DouyinOpenSDKPresentProfileCompletion callback;
@property (nonatomic, strong) DouyinOpenSDKProfileContext * context;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, assign) NSInteger errCode;
@property (nonatomic, copy, nullable) NSString *errMsg;

- (IBAction)questionPressed:(id)sender;

@end



NS_ASSUME_NONNULL_END

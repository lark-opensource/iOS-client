//
//  DouyinOpenSDKProfileVideoViewController.h
//  DouyinOpenPlatformSDK
//
//  Created by bytedance on 2022/3/1.
//
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>
#import "DouyinOpenSDKProfileVideoModel.h"
#import "DouyinOpenSDKProfileViewController.h"
#import "DYOpenNetworkManager.h"

typedef void(^followCallback)(void);

@interface DouyinOpenSDKProfileVideoViewController:UIViewController
@property (nonatomic, strong) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *likesLabel;
@property (nonatomic, strong) IBOutlet UILabel *commentsLabel;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *descLabel;
@property (nonatomic, strong) IBOutlet UILabel *musicLabel;
@property (nonatomic, strong) IBOutlet UIImageView *likeImageView;
@property (nonatomic, strong) IBOutlet UIImageView *commentImageView;
@property (nonatomic, strong) IBOutlet UIImageView *shareImageView;
@property (nonatomic, strong) IBOutlet UIImageView *dotsImageView;
@property (nonatomic, strong) IBOutlet UIButton *backButtonImageView;
@property (nonatomic, strong) DouyinOpenSDKProfileVideoModel*videoModel;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, assign) DouyinOpenSDKProfileVCType vcType;
@property (nonatomic, strong) IBOutlet UIButton *pauseButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIStackView *nameDescStackView;
- (IBAction)pausePressed:(id)sender;
@property (nonatomic, strong) DouyinOpenSDKProfileContext * context;
@property (nonatomic, strong) UIImage* avatarImage;
@end

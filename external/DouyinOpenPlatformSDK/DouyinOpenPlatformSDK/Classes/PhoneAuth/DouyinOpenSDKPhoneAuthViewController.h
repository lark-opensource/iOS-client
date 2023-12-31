//
//  DouyinOpenSDKPhoneAuthViewController.h
//  Pods
//
//  Created by bytedance on 2022/5/6.
//

#import "DouyinOpenSDKAuth.h"

@class DouyinOpenSDKPhoneAuthManager;
@interface DouyinOpenSDKPhoneAuthViewController : UIViewController

@property (nonatomic, strong) DouyinOpenSDKAuthRequest *req;
@property (nonatomic, copy) DouyinOpenSDKAuthCompleteBlock callBack;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *topTipLabel; // 最顶部的 “抖音关联授权”
@property (nonatomic, strong) IBOutlet UIView *lineView; // topTipLabel 下面的一条线
@property (nonatomic, strong) IBOutlet UIView *scopeTipsView; // scope 列表下面的一行文字，提示去管理相关权限的位置
@property (nonatomic, strong) IBOutlet UIButton *otherAccsButton;
@property (nonatomic, strong) IBOutlet UIImageView *dyIconImageView;
@property (nonatomic, strong) IBOutlet UIImageView *doubleArrowImageView;
@property (nonatomic, strong) IBOutlet UIImageView *hostIconImageView;
@property (nonatomic, strong) IBOutlet UIButton *agreeButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *phoneNumberLabel;
@property (nonatomic, strong) IBOutlet UILabel *tableHeaderLabel;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *tableViewHeight;
@property (nonatomic, strong) IBOutlet UILabel *agreementLabel;
@property (nonatomic, strong) IBOutlet UIButton *agreementBackgroundButton;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *nonPlaceholderViews;
@property (nonatomic, strong) IBOutlet UIImageView *agreementImageView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *topConstraint;
@property (nonatomic, assign) BOOL useHalf;
@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) DouyinOpenSDKPhoneAuthManager *phoneAuthManager;

@end


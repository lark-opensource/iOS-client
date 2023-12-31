//
//  DYOpenAlertViewController.h
//  Pods
//
//  Created by bytedance on 2022/3/9.
//

#import "DouyinOpenSDKProfile.h"

@interface DYOpenAlertViewController:UIViewController

typedef void (^alertFailClosure)(UIAlertAction *);

@property (nonatomic, strong) IBOutlet UIView *alertView;

@end

@interface DYOpenYesNoViewController:UIViewController
@property (nonatomic, copy) NSString* awemeId;
@property (nonatomic, copy) NSString* openId;
@property (nonatomic, copy) NSString* targetOpenId;
@property (nonatomic, copy) NSString* accessToken;
@property (nonatomic, assign) NSInteger flag;
@property (nonatomic, copy) DouyinOpenSDKPlayJumpCompletion alertFailCallback;
@property (nonatomic, strong) IBOutlet UILabel *label;
@property (nonatomic, strong) IBOutlet UIView *alertView;

@end

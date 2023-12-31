//
//  KALoginDemoViewController.m
//  KALoginDemo
//
//  Created by bytedance on 2021/12/20.
//

#import "KASSOViewController.h"

@import LKAppLinkExternal;
@import KALogin;
@import MBProgressHUD;

@interface KASSOViewController ()

@property (nonatomic, strong) UITextField *userNameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UIButton *loginBtn;
@property (nonatomic, copy) NSString *redirectUrl;

@end

@implementation KASSOViewController

- (instancetype)initWithRedirectUrl: (NSString *)url {
    if (self = [super init]) {
        self.redirectUrl = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self makeSubviews];
}

- (void)makeSubviews {

    UITextField *nameTextField = UITextField.new;
    nameTextField.translatesAutoresizingMaskIntoConstraints = NO;
    nameTextField.placeholder = @"用户名";
    nameTextField.borderStyle = UITextBorderStyleRoundedRect;
    nameTextField.text = @"zhangfei";

    UITextField *passportTextField = UITextField.new;
    passportTextField.translatesAutoresizingMaskIntoConstraints = NO;
    passportTextField.placeholder = @"密码";
    passportTextField.borderStyle = UITextBorderStyleRoundedRect;
    passportTextField.secureTextEntry = YES;
    passportTextField.text = @"zhangfei";

    UIButton *loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    loginBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [loginBtn setTitle:@"登录" forState:UIControlStateNormal];
    [loginBtn setTitleColor: [UIColor blueColor] forState:UIControlStateNormal];
    [loginBtn addTarget:self action:@selector(handleLoginAction:) forControlEvents:UIControlEventTouchUpInside];


    [self.view addSubview:nameTextField];
    [self.view addSubview:passportTextField];
    [self.view addSubview:loginBtn];
    self.userNameTextField = nameTextField;
    self.passwordTextField = passportTextField;
    self.loginBtn = loginBtn;

    //layout
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[nameTextField, passportTextField, loginBtn]];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.spacing = 8;
    [self.view addSubview:stackView];
    [stackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [stackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:100].active = YES;
    [stackView.widthAnchor constraintEqualToConstant:300].active = YES;
}


- (void)handleLoginAction:(UIButton *)sender {

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
    hud.label.text = @"登录中";
    __weak typeof(self)weakself = self;
    [[KALoginAPI sharedInstance] verifyForOCWithRedirectURL:self.redirectUrl completion:^(NSString * _Nullable validateUrl, NSError * _Nullable error) {
        __strong typeof(weakself)strongself = weakself;
        if (!strongself) return;

        if (validateUrl) {
            [[KALoginAPI sharedInstance] validateForOCWithUrl:[NSURL URLWithString:validateUrl] completion:^(NSString * _Nullable callbackUrl, NSError * _Nullable error) {
                __strong typeof(weakself)strongself = weakself;
                if (!strongself) return;
                if (callbackUrl) {
                    [MBProgressHUD hideHUDForView: strongself.view animated: true];
                    [LKAppLinkExternal open:[NSURL URLWithString:callbackUrl] from: strongself];
                }
            }];
        } else if (error) {
            NSLog(@"handle error %@", error.localizedFailureReason);
        }
    }];
}

@end

//
//  BDTuringEmailViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2021/3/17.
//

#import "BDTuringEmailViewController.h"

#import <TTAccountSDK/TTAccountSDK.h>

@interface BDTuringEmailViewController ()

@property (nonatomic, strong) UITextField *emailTextField;
@property (nonatomic, strong) UITextField *codeTextField;
@property (nonatomic, strong) UIButton *sendCodeButton;
@property (nonatomic, strong) UIButton *bindButton;


@property (nonatomic, strong) UITextField *oldCodeText;
@property (nonatomic, strong) UIButton *sendOldCodeButton;
@property (nonatomic, strong) UIButton *valiOldCodeButton;

@property (nonatomic, strong) NSString *ticket;

@end

@implementation BDTuringEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 100, 300, 30)];
    self.emailTextField.text = @"verifytest001@gmail.com";
    self.emailTextField.layer.borderWidth = 1;
    self.emailTextField.layer.cornerRadius = 5;
    [self.view addSubview:self.emailTextField];
    
    self.codeTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 150, 300, 30)];
    self.codeTextField.layer.borderWidth = 1;
    self.codeTextField.layer.cornerRadius = 5;
    [self.view addSubview:self.codeTextField];
    
    self.sendCodeButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 200, 100, 40)];
    [self.sendCodeButton setTitle:@"send code" forState:UIControlStateNormal];
    [self.sendCodeButton setBackgroundColor:[UIColor blueColor]];
    [self.sendCodeButton addTarget:self action:@selector(sendCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendCodeButton];
    
    self.bindButton = [[UIButton alloc] initWithFrame:CGRectMake(150, 200, 100, 40)];
    [self.bindButton setTitle:@"bind email" forState:UIControlStateNormal];
    [self.bindButton setBackgroundColor:[UIColor systemPinkColor]];
    [self.bindButton addTarget:self action:@selector(bindEmail) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.bindButton];
    
    
    self.oldCodeText = [[UITextField alloc] initWithFrame:CGRectMake(10, 300, 300, 30)];
    self.oldCodeText.layer.borderWidth = 1;
    self.oldCodeText.layer.cornerRadius = 5;
    [self.view addSubview:self.oldCodeText];
    
    self.sendOldCodeButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 360, 100, 40)];
    [self.sendOldCodeButton setTitle:@"send old code" forState:UIControlStateNormal];
    [self.sendOldCodeButton setBackgroundColor:[UIColor purpleColor]];
    [self.sendOldCodeButton addTarget:self action:@selector(sendOldCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendOldCodeButton];
    
    self.valiOldCodeButton = [[UIButton alloc] initWithFrame:CGRectMake(150, 360, 100, 40)];
    [self.valiOldCodeButton setTitle:@"vali old code" forState:UIControlStateNormal];
    [self.valiOldCodeButton setBackgroundColor:[UIColor greenColor]];
    [self.valiOldCodeButton addTarget:self action:@selector(valiCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.valiOldCodeButton];
    
}

- (void)sendOldCode {
    [TTAccount getEmailCodeWithEmail:@"yanming.sysu@bytedance.com" emailCodeType:TTASMSCodeScenarioValidateEmail password:nil jumpUrl:nil captcha:nil completion:^(UIImage * _Nullable captchaImage, NSError * _Nullable error) {
        
    }];
}

- (void)valiCode {
    [TTAccount requestVerifyEmailWithCode:self.oldCodeText.text emailCodeType:TTASMSCodeScenarioValidateEmail completion:^(NSError * _Nullable error, NSString * _Nullable ticket, id  _Nullable jsonObj) {
        self.ticket = jsonObj[@"data"][@"ticket"];
    }];
}

- (void)sendCode {
    [TTAccount getEmailCodeWithEmail:self.emailTextField.text emailCodeType:TTASMSCodeScenarioChangeEmail password:nil jumpUrl:nil captcha:nil completion:^(UIImage * _Nullable captchaImage, NSError * _Nullable error) {
        
    }];
}

- (void)bindEmail {
    [TTAccount changeEmailWithNewEmail:self.emailTextField.text verifyCode:self.codeTextField.text ticket:self.ticket completion:^(id _Nullable jsonObj, NSError * _Nullable error) {
        
    }];
}


@end

//
//  BDTVLoginViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/12/1.
//

#import "BDTVLoginViewController.h"
#import "NSDictionary+BDTuring.h"
#import "BDTwiceVerifyViewController.h"
#import "BDTuring.h"
#import "BDTuringConfig.h"
#import "BDTuringTwiceVerify.h"
#import "BDTuringVerifyModel+Creator.h"
#import "BDTuring+Private.h"

#import "BDTuringConfig+SMSCode.h"
#import "BDTuring+SMSCode.h"
#import "BDTuringSendCodeModel.h"
#import "BDTuringCheckCodeModel.h"
#import "BDTuringSMSCodeResult.h"
#import "BDTuringStartUpTask.h"
#import "BDTuring+InHouse.h"
#import "NSString+BDTuring.h"
#import <TTAccountSDK/TTAccountSDK.h>

@interface BDTVLoginViewController ()

@property (nonatomic, strong) UITextField *phoneNumberInputTextField;
@property (nonatomic, strong) UITextField *verifyCodeInputTextField;

@property (nonatomic, strong) UIButton *sendCodeButton;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *getCodeButton;
@property (nonatomic, strong) UIButton *checkCodeButton;

@property (nonatomic, strong) NSString *appID;

@end

@implementation BDTVLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [self locatePhoneNumberInputTextField];
    [self locateVerifyCodeInputTextField];
    [self locateButtons];
    
    self.appID = [BDTuringStartUpTask sharedInstance].config.appID;
}

- (void)locatePhoneNumberInputTextField {
    self.phoneNumberInputTextField = [UITextField new];
    self.phoneNumberInputTextField.placeholder = @" Phone Number";
    self.phoneNumberInputTextField.text = @"12341861076";
    self.phoneNumberInputTextField.layer.borderWidth = 1;
    self.phoneNumberInputTextField.layer.cornerRadius = 5;
    [self.view addSubview:self.phoneNumberInputTextField];
    self.phoneNumberInputTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:80]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:-80]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:200]];
    [self.phoneNumberInputTextField addConstraint:[NSLayoutConstraint constraintWithItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50]];
}

- (void)locateVerifyCodeInputTextField {
    self.verifyCodeInputTextField = [UITextField new];
    self.verifyCodeInputTextField.placeholder = @"Verify Code";
    self.verifyCodeInputTextField.text = @"1390";
    self.verifyCodeInputTextField.layer.borderWidth = 1;
    self.verifyCodeInputTextField.layer.cornerRadius = 5;
    [self.view addSubview:self.verifyCodeInputTextField];
    self.verifyCodeInputTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.verifyCodeInputTextField attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.verifyCodeInputTextField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.verifyCodeInputTextField attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.verifyCodeInputTextField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeBottom multiplier:1 constant:40]];
}

- (void)locateButtons {
    self.checkCodeButton = [UIButton new];
    [self.checkCodeButton setTitle:@"Check Code" forState:UIControlStateNormal];
    self.checkCodeButton.backgroundColor = [UIColor systemPinkColor];
    self.checkCodeButton.layer.cornerRadius = 5;
    [self.checkCodeButton addTarget:self action:@selector(checkSMSSCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.checkCodeButton];
    
    self.sendCodeButton = [UIButton new];
    [self.sendCodeButton setTitle:@"Send Code" forState:UIControlStateNormal];
    self.sendCodeButton.backgroundColor = [UIColor systemPinkColor];
    self.sendCodeButton.layer.cornerRadius = 5;
    [self.sendCodeButton addTarget:self action:@selector(sendSMSCode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendCodeButton];
    
    self.loginButton = [UIButton new];
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemPinkColor];
    self.loginButton.layer.cornerRadius = 5;
    [self.loginButton addTarget:self action:@selector(loginButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    
    self.getCodeButton = [UIButton new];
    [self.getCodeButton setTitle:@"获取验证码" forState:UIControlStateNormal];
    self.getCodeButton.backgroundColor = [UIColor systemPinkColor];
    self.getCodeButton.layer.cornerRadius = 5;
    [self.getCodeButton addTarget:self action:@selector(getCodeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.getCodeButton];
    
    self.getCodeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.checkCodeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.sendCodeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.loginButton addConstraint:[NSLayoutConstraint constraintWithItem:self.loginButton
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1
                                                                  constant:100]];
    [self.loginButton addConstraint:[NSLayoutConstraint constraintWithItem:self.loginButton
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1
                                                                  constant:40]];
    
    [self.checkCodeButton addConstraint:[NSLayoutConstraint constraintWithItem:self.checkCodeButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:120]];
    [self.checkCodeButton addConstraint:[NSLayoutConstraint constraintWithItem:self.checkCodeButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];
    
    
    [self.sendCodeButton addConstraint:[NSLayoutConstraint constraintWithItem:self.sendCodeButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:120]];
    [self.sendCodeButton addConstraint:[NSLayoutConstraint constraintWithItem:self.sendCodeButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];
    
    [self.getCodeButton addConstraint:[NSLayoutConstraint constraintWithItem:self.getCodeButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:120]];
    [self.getCodeButton addConstraint:[NSLayoutConstraint constraintWithItem:self.getCodeButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:40]];
    
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.getCodeButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.verifyCodeInputTextField attribute:NSLayoutAttributeBottom multiplier:1 constant:80]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.getCodeButton attribute:NSLayoutAttributeBottom multiplier:1 constant:20]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.sendCodeButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.loginButton attribute:NSLayoutAttributeBottom multiplier:1 constant:20]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.checkCodeButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.sendCodeButton attribute:NSLayoutAttributeBottom multiplier:1 constant:20]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.getCodeButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.sendCodeButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.checkCodeButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.phoneNumberInputTextField attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
}

- (void)sendSMSCode {
    BDTuringSendCodeModel *model = [BDTuringSendCodeModel new];
    model.requestURL = @"https://gmp-boe.byted.org/notify/sms/app/send_code";
    model.scene = 0;
    model.eventType = 0;
    model.channelID = 781;
    model.vid = @"961CF8F0-AA1F-4FC7-81DB-FCE94C299028";
    model.mobile = self.phoneNumberInputTextField.text;
    model.callback = ^(BDTuringVerifyResult * _Nonnull result) {
        [self twiceverify_showAlertWithMessage:[NSString stringWithFormat:@"结果 %zd", result.status]];
    };
    [[BDTuring turingWithAppID:self.appID] sendCodeWithModel:model];
}

- (void)checkSMSSCode {
    BDTuringCheckCodeModel *model = [BDTuringCheckCodeModel new];
    model.requestURL = @"https://gmp-boe.byted.org/notify/sms/check_code";
    model.code = self.verifyCodeInputTextField.text;
    model.scene = 0;
    model.mobile = self.phoneNumberInputTextField.text;
    model.callback = ^(BDTuringVerifyResult * _Nonnull result) {
        [self twiceverify_showAlertWithMessage:[NSString stringWithFormat:@"结果 %zd", result.status]];
    };
    [[BDTuring turingWithAppID:self.appID] checkCodeWithModel:model];
}

- (void)handleResponse:(NSDictionary *)jsonObj {
    if ([jsonObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *data = [jsonObj turing_dictionaryValueForKey:@"data"];
        if ([data isKindOfClass:[NSDictionary class]]) {
            NSString *verifyTicket = [data turing_stringValueForKey:@"verify_ticket"];
            if (verifyTicket != nil) {
                NSString *decision = [data turing_stringValueForKey:@"verify_center_secondary_decision_conf"];
                BDTuringVerifyModel *tvModel = [BDTuringVerifyModel parameterModelWithParameter:[decision turing_dictionaryFromJSONString]];
                tvModel.callback = ^(BDTuringVerifyResult * _Nonnull result) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    pasteboard.string = verifyTicket;
                    [self twiceverify_showAlertWithMessage:@"verify_ticket已经粘贴到粘贴板"];
                };
                [[BDTuringTwiceVerify twiceVerifyWithAppID:self.appID] popVerifyViewWithModel:tvModel];
            } else {
                [self twiceverify_showAlertWithMessage:@"登录成功,未命中风控"];
            }
        }
    } else {
        [self twiceverify_showAlertWithMessage:@"成功,未命中风控"];
    }
}

- (void)getCodeButtonClick {
    [TTAccount sendSMSCodeWithPhoneToLogin:self.phoneNumberInputTextField.text completion:^(NSNumber * _Nullable retryTime, NSError * _Nullable error) {
        if(error.userInfo != nil) {
//            jsonObj = [BDTuring inhouseCustomValueForKey:@"test"];
            NSDictionary *jsonObj = [error.userInfo turing_dictionaryValueForKey:@"original_response_object"];
            [self handleResponse:jsonObj];
        } else {
            [self twiceverify_showAlertWithMessage:@"成功,未命中风控"];
        }
    }];
}

- (void)loginButtonClick {
    [TTAccount quickLoginWithPhone:self.phoneNumberInputTextField.text SMSCode:self.verifyCodeInputTextField.text captcha:nil jsonObjCompletion:^(UIImage * _Nullable captchaImage, NSError * _Nullable error, id  _Nullable jsonObj) {
        [self handleResponse:jsonObj];
    }];
}

- (void)twiceverify_showAlertWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

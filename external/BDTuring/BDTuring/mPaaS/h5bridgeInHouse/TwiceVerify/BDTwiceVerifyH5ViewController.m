//
//  BDTwiceVerifyH5ViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2021/3/10.
//

#import "BDTwiceVerifyH5ViewController.h"
#import "BDTuringFullScreenH5ViewController.h"
#import "BDTuringH5VerifyModel.h"

#import <WebKit/WebKit.h>

@interface BDTwiceVerifyH5ViewController ()

@property (nonatomic, strong) UITextView *urlTextView;
@property (nonatomic, strong) UITextField *ppeTextField;
@property (nonatomic, strong) UISwitch *ppeSwitch;
@property (nonatomic, strong) UITextView *ppeTitle;
@property (nonatomic, strong) UIButton *startTestButton;

@end

static NSString *url = @"http://i.snssdk.com/passport/authentication/index/?locale=zh&aid=1991&scene=global_payment&use_by_native_shell=0&redirect_url=%2F%2Fwww.douyin.com&decision_config=block-sms&verify_ticket=";
static NSString *ppeDefaultString = @"ppe_zby_goapi_v4";

@implementation BDTwiceVerifyH5ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self locateTextField];
    [self locateSwitch];
    [self locateButton];
}

- (void)locateTextField {
    self.urlTextView = [UITextView new];
    self.urlTextView.text = url;
    self.urlTextView.layer.borderWidth = 1;
    self.urlTextView.layer.cornerRadius = 5;
    [self.view addSubview:self.urlTextView];
    self.urlTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.urlTextView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.urlTextView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:-10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.urlTextView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:100]];
    [self.urlTextView addConstraint:[NSLayoutConstraint constraintWithItem:self.urlTextView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
    
    self.ppeTextField = [UITextField new];
    self.ppeTextField.text = ppeDefaultString;
    self.ppeTextField.layer.borderWidth = 1;
    self.ppeTextField.layer.cornerRadius = 5;
    [self.view addSubview:self.ppeTextField];
    self.ppeTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeTextField attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeTextField attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:-10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeTextField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.urlTextView attribute:NSLayoutAttributeBottom multiplier:1 constant:30]];
    [self.ppeTextField addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeTextField attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50]];
}

- (void)locateSwitch {
    self.ppeTitle = [UITextView new];
    self.ppeSwitch = [UISwitch new];
    [self.view addSubview:self.ppeTitle];
    [self.view addSubview:self.ppeSwitch];
    self.ppeTitle.translatesAutoresizingMaskIntoConstraints = NO;
    self.ppeSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeTitle attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.ppeTextField attribute:NSLayoutAttributeBottom multiplier:1 constant:50]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeTitle attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.ppeSwitch attribute:NSLayoutAttributeLeft multiplier:1 constant:-10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:30]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeSwitch attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.ppeTitle attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeSwitch attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.ppeTitle attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.ppeTitle addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeTitle attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:30]];
    [self.ppeTitle addConstraint:[NSLayoutConstraint constraintWithItem:self.ppeTitle attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60]];
}

- (void)locateButton {
    self.startTestButton = [UIButton new];
    [self.startTestButton setTitle:@"开始H5测试" forState:UIControlStateNormal];
    [self.startTestButton setBackgroundColor:[UIColor blueColor]];
    self.startTestButton.layer.cornerRadius = 5;
    [self.startTestButton addTarget:self action:@selector(startTest) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startTestButton];
    self.startTestButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.startTestButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.ppeTitle attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.startTestButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.ppeTitle attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.startTestButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:-80]];
    [self.startTestButton addConstraint:[NSLayoutConstraint constraintWithItem:self.startTestButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:120]];
}

- (void)startTest {
    BDTuringH5VerifyModel *model = [BDTuringH5VerifyModel new];
    model.url = self.urlTextView.text;
    model.ppeString = self.ppeTextField.text;
    model.useppe = self.ppeSwitch.isOn;
    
    BDTuringFullScreenH5ViewController *vc = [[BDTuringFullScreenH5ViewController alloc] initWithModel:model];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

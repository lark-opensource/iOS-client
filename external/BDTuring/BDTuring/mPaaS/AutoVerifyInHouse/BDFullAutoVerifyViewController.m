//
//  BDFullAutoVerifyViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/10.
//

#import "BDFullAutoVerifyViewController.h"
#import "BDAutoVerifyView.h"
#import <BDStartUp/BDApplicationInfo.h>
#import "BDAutoVerify.h"
#import "BDTuring.h"
#import "BDAutoVerifyModel.h"
#import "BDTuringVerifyView.h"
#import "BDDebugFeedTuring.h"
#import "BDTuringConfig.h"
#import "BDAutoVerifyMaskView.h"

@interface BDFullAutoVerifyViewController ()

@property (nonatomic, strong) BDAutoVerifyView *verifyView;
@property (nonatomic, strong) BDAutoVerifyMaskView *maskView;
@property (nonatomic, strong) UIButton *button;

@end

@implementation BDFullAutoVerifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.button = [[UIButton alloc] initWithFrame:CGRectMake(30, 400, 200, 100)];
    [self.button setBackgroundColor:[UIColor systemPinkColor]];
    [self.view addSubview:self.button];
    
    NSString *appid = [BDApplicationInfo sharedInstance].appID;
    BDTuring *turing = [BDTuring turingWithAppID:appid];
    
    BDAutoVerify *verify = [[BDAutoVerify alloc] initWithTuring:turing];
    
    BDAutoVerifyModel *model = [[BDAutoVerifyModel alloc] initWithFrame:self.button.frame maskView:YES];
    model.callback = ^(BDTuringVerifyResult * _Nonnull result) {
        [self autoverify_showAlertWithMessage:[NSString stringWithFormat:@"验证结果:%zd",result.status]];
    };
    model.regionType = [BDDebugFeedTuring sharedInstance].config.regionType;
    
    self.maskView = [verify autoVerifyMaskViewWithModel:model];
    
    [self.button addSubview:self.maskView];
}

- (void)autoverify_showAlertWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

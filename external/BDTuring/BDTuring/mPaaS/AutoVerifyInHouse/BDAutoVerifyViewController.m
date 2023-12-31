//
//  GestureTestViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/5.
//

#import "BDAutoVerifyViewController.h"
#import "BDAutoVerifyView.h"
#import <BDStartUp/BDApplicationInfo.h>
#import "BDAutoVerify.h"
#import "BDTuring.h"
#import "BDAutoVerifyModel.h"
#import "BDTuringVerifyView.h"
#import "BDDebugFeedTuring.h"
#import "BDTuringConfig.h"

@interface BDAutoVerifyViewController ()

@property (nonatomic, strong) BDAutoVerifyView *verifyView;

@end

@implementation BDAutoVerifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    NSString *appid = [BDApplicationInfo sharedInstance].appID;
    BDTuring *turing = [BDTuring turingWithAppID:appid];
    
    BDAutoVerify *verify = [[BDAutoVerify alloc] initWithTuring:turing];
    
    BDAutoVerifyModel *model = [[BDAutoVerifyModel alloc] initWithFrame:CGRectMake(30, 400, 311, 44)];
    model.callback = ^(BDTuringVerifyResult * _Nonnull result) {
        [self autoverify_showAlertWithMessage:[NSString stringWithFormat:@"验证结果:%zd",result.status]];
    };
    model.regionType = [BDDebugFeedTuring sharedInstance].config.regionType;
    
    self.verifyView = [verify autoVerifyViewWithModel:model];
    
    [self.view addSubview:self.verifyView];
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

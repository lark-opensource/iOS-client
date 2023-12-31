//
//  BDTwiceVerifyViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/5.
//

#import "BDTwiceVerifyViewController.h"
#import "BDTuringTwiceVerify.h"
#import "BDTuringTVConverter.h"
#import "BDTVLoginViewController.h"
#import "BDTuringTwiceVerifyModel.h"
#import "BDTuring.h"
#import "BDTNetworkManager.h"
#import "BDTuringConfig+Parameters.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringParameter.h"
#import "BDTuringDefine.h"
#import "BDTuringVerifyResult.h"
#import "BDTuring+Private.h"
#import "BDTuringEmailViewController.h"
#import "BDTuringMacro.h"
#import "BDTuringTVAppNetworkRequestSerializer.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuringTVHelper.h"
#import "BDTuringStartUpTask.h"
#import <TTBridgeUnify/TTBridgeAuthManager.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTAccountSDK/TTAccountSDK.h>
#import <BDStartUp/BDApplicationInfo.h>

@interface BDTwiceVerifyViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSArray *dataArr;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSString *appID;


@end

@implementation BDTwiceVerifyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.appID = [BDTuringStartUpTask sharedInstance].config.appID;
    self.dataArr = @[
        @{@"name": @"下行短信", @"type": kBDTuringTVBlockSms},
        @{@"name": @"上行短信", @"type": kBDTuringTVBlockUpsms},
        @{@"name": @"密码验证", @"type": kBDTuringTVBlockPassword},
        @{@"name": @"邮箱验证", @"type": kBDTuringTVBlockEmail},
        @{@"name": @"语音验证码", @"type": @"mobile_voice_sms_verify"},
        @{@"name": @"决策透传", @"type": @"decision"},
        @{@"name": @"点击登录", @"type": @"login"},
        @{@"name": @"邮箱相关", @"type":@"email"},
    ];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.mobile = @"12341861076";
    [self.view addSubview:self.tableView];
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    NSDictionary *curInfo = self.dataArr[indexPath.row];
    cell.textLabel.text = curInfo[@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *curInfo = self.dataArr[indexPath.row];
    NSMutableDictionary *paramDic = @{kBDTuringTVDecisionConfig :curInfo[@"type"]}.mutableCopy; // 实名验证: block-info_verify 活体验证: block-face 下行短信：block-sms
    if ([curInfo[@"type"] isEqualToString:@"login"]) {
        BDTVLoginViewController *loginVC = [BDTVLoginViewController new];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    }
    
    if ([curInfo[@"type"] isEqualToString:@"decision"]) {
        [self startTVDecision];
        return;
    }
    
    if ([curInfo[@"type"] isEqualToString:@"email"]) {
        BDTuringEmailViewController *loginVC = [BDTuringEmailViewController new];
        [self.navigationController pushViewController:loginVC animated:YES];
        return;
    }
    
    BDTuringTwiceVerify *twiceIns = [BDTuringTwiceVerify twiceVerifyWithAppID:self.appID];
    BDTuringTwiceVerifyRequest *request = [[BDTuringTwiceVerifyRequest alloc] init];
    request.params = [paramDic copy];
    BDTuringTwiceVerifyModel *model = turing_tvRequestToModel(request);
    [twiceIns popVerifyViewWithModel:model callback:^(BDTuringTwiceVerifyResponse *response) {
        if (response.error != nil) {
            [self twiceverifyVC_showAlertWithMessage:response.error.domain];
        } else {
            [self twiceverifyVC_showAlertWithMessage:@"verify success"];
        }
    }];
}

- (void)startTVDecision {
    [TTAccount sendSMSCodeWithPhone:self.mobile
                            captcha:nil
                        SMSCodeType:24
                          extraInfo:nil
                         completion:^(id  _Nullable data, NSError * _Nullable error) {
        if (error != nil) {
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSString *decisionConfig = [[data turing_dictionaryValueForKey:@"data"] turing_stringValueForKey:@"verify_center_decision_conf"];
                if (decisionConfig != nil) {
                    NSError *error = nil;
                    NSDictionary *decisionConfigDic = [NSJSONSerialization JSONObjectWithData:[decisionConfig dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
                    if (error == nil && decisionConfigDic != nil) {
                        [[BDTuringParameter sharedInstance] updateCurrentParameter:decisionConfigDic];
                        [[BDTuring turingWithAppID:self.appID] popVerifyViewWithCallback:^(BDTuringVerifyResult *result) {
                            [self twiceverifyVC_showAlertWithMessage:[NSString stringWithFormat:@"验证结果 status(%zd)", result.status]];
                        }];
                    }
                }
            }
        }
    }];
}

- (void)twiceverifyVC_showAlertWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


@end

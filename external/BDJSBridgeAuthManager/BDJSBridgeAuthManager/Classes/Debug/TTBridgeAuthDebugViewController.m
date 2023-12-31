//
//  TTBridgeAuthDebugViewController.m
//  TTBridgeUnify
//
//  Created by liujinxing on 2020/8/13.
//

#import <Godzippa/NSData+Godzippa.h>
#import "IESBridgeAuthManager+BDJSBridgeAuthDebug.h"
#import "TTBridgeAuthDebugViewController.h"
#import "TTBridgeAuthInfoViewController.h"
#import "TTBridgeAuthInfoDiffViewController.h"
#import <ByteDanceKit/BTDMacros.h>
#import <TTNetworkManager/TTNetworkManager.h>


#pragma mark - TTBridgeAuthDebugViewController

@implementation TTBridgeAuthDebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSMutableArray *dataSource = [NSMutableArray array];
    NSMutableArray *itemArray = [NSMutableArray array];
    
    STTableViewCellItem *getBuiltinAuthInfosItem = [[STTableViewCellItem alloc] initWithTitle:@"Inner Gecko Piper AllowList" target:self action:@selector(getBuiltinAuthInfos)];
    [itemArray addObject:getBuiltinAuthInfosItem];

    STTableViewCellItem *fetchAuthInfosItem = [[STTableViewCellItem alloc] initWithTitle:@"Online Gecko Piper AllowList" target:self action:@selector(fetchAuthInfos)];
    [itemArray addObject:fetchAuthInfosItem];
    
    STTableViewCellItem *compareAuthInfosItem = [[STTableViewCellItem alloc] initWithTitle:@"Compare Inner And Online Allowlist" target:self action:@selector(compareAuthInfos)];
    [itemArray addObject:compareAuthInfosItem];
    
    STTableViewCellItem *bypassJSBAuthEnabledItem = [[STTableViewCellItem alloc] initWithTitle:@"BOE URL Bypass Authorization" target:self action:nil];
    bypassJSBAuthEnabledItem.switchStyle = YES;
    bypassJSBAuthEnabledItem.switchAction = @selector(bypassJSBAuthEnabled:);
    bypassJSBAuthEnabledItem.checked = IESBridgeAuthManager.sharedManager.isBypassJSBAuthEnabled;
    [itemArray addObject:bypassJSBAuthEnabledItem];

    STTableViewSectionItem *section = [[STTableViewSectionItem alloc] initWithSectionTitle:@"Piper Gecko Auth Debug" items:itemArray];
    [dataSource addObject:section];

    self.dataSource = dataSource;
}

- (void)getBuiltinAuthInfos{
    @weakify(self);
    [IESBridgeAuthManager getBuiltInAuthInfosWithCompletion:^(NSError * _Nullable error, id  _Nullable jsonObj) {
        @strongify(self);
        if (!error && [jsonObj isKindOfClass:NSDictionary.class]) {
            NSString *accessKey = IESBridgeAuthManager.requestParams.accessKey;
            TTBridgeAuthInfoViewController *authDetailViewController = [[TTBridgeAuthInfoViewController alloc]initWithTitle:@"Inner Gecko Piper AllowList" JSON:jsonObj accessKey:accessKey];
            [self.navigationController pushViewController:authDetailViewController animated:YES];
            return;
        }
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.description preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:true completion:nil];
        }
        else{
            NSString *msg = jsonObj ? @"The data is not a dictionary!" : @"Inner Gecko Piper AllowList is Empty!";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:true completion:nil];
        }
    }];
}

- (void)fetchAuthInfos{
    @weakify(self);
    [IESBridgeAuthManager fetchAuthInfosWithCompletion:^(NSError * _Nonnull error, id  _Nonnull jsonObj) {
        @strongify(self);
        if (!error && [jsonObj isKindOfClass:NSDictionary.class]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *accessKey = IESBridgeAuthManager.requestParams.accessKey;
                TTBridgeAuthInfoViewController *authDetailViewController = [[TTBridgeAuthInfoViewController alloc]initWithTitle:@"Online Gecko Piper AllowList" JSON:jsonObj accessKey:accessKey];
                [self.navigationController pushViewController:authDetailViewController animated:YES];
            });
            return;
        }
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.description preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:true completion:nil];
            });
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *msg = jsonObj ? @"The data is not a dictionary!" : @"Online Gecko Piper AllowList is Empty!";
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:true completion:nil];
            });
        }
    }];
}

- (void)compareAuthInfos{
    @weakify(self);
    [IESBridgeAuthManager getBuiltInAuthInfosWithCompletion:^(NSError * _Nullable error, id  _Nullable jsonObj) {
        @strongify(self);
        if (!error && [jsonObj isKindOfClass:NSDictionary.class]) {
            NSDictionary *localJson = jsonObj;
            [IESBridgeAuthManager fetchAuthInfosWithCompletion:^(NSError * _Nullable error, id  _Nullable jsonObj) {
                if (!error && [jsonObj isKindOfClass:NSDictionary.class]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *accessKey = IESBridgeAuthManager.requestParams.accessKey;
                        TTBridgeAuthInfoDiffViewController *authInfoDiffViewController = [[TTBridgeAuthInfoDiffViewController alloc]initWithTitle:@"Compare Inner And Online Allowlist" JSON:localJson ComparedJSON:jsonObj accessKey:accessKey];
                        [self.navigationController pushViewController:authInfoDiffViewController animated:YES];
                    });
                    return;
                }
                if (error){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed to get Online Gecko Piper AllowList!" message:error.description preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:alert animated:true completion:nil];
                    });
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *msg = jsonObj ? @"The data is not a dictionary!" : @"Online Gecko Piper AllowList is Empty!";
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:alert animated:true completion:nil];
                    });
                }
            }];
            return;
        }
        if (error){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed to get Inner Gecko Piper AllowList!" message:error.description preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:true completion:nil];
        }
        else{
            NSString *msg = jsonObj ? @"The data is not a dictionary!" : @"Inner Gecko Piper AllowList is Empty!";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:true completion:nil];
        }
    }];
}

- (void)bypassJSBAuthEnabled:(UISwitch *)uiswitch {
    IESBridgeAuthManager.sharedManager.bypassJSBAuthEnabled = uiswitch.isOn;
}
@end

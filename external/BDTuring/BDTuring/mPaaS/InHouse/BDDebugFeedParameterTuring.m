//
//  BDDebugFeedParameterTuring.m
//  BDTuring
//
//  Created by bob on 2020/7/15.
//

#import "BDDebugFeedParameterTuring.h"
#import "BDDebugFeedTuring.h"
#import "BDTuringConfig.h"
#import "BDTuringDefine.h"
#import "BDTuring.h"
#import "BDTNetworkManager.h"
#import "NSData+BDTuring.h"
#import "NSDictionary+BDTuring.h"
#import "NSString+BDTuring.h"
#import "BDTuringUtility.h"
#import "PreloadViewController.h"
#import "BDTuringParameter.h"
#import <BDDebugTool/BDDebugFeedModel.h>

static NSString *const DebugFakeURL     = @"https://rc-boe.snssdk.com/self/unpunish/v1/test_get_decision_conf_simple";
static NSString *const DebugFakeURLHeader     = @"http://rc-boe.snssdk.com/self/unpunish/v1/test_get_decision_conf?uid=111&did=222&iid=333&aid=24&rule_engine_type=shark_admin&exempt_duration=60&punish_duration=60&verify_type=&version_code=980&device_platform=ios&app_key=123&config_id=123&decision_conf=1,1105&verify_ticket=12121&channel_mobile=13828819104&mobile=133828819104&sec_user_id=11wqwwqwq&auth_ticket=sadasdasda";
static NSString *const kDebugFakeType   = @"verify_type";

@interface BDDebugFeedParameterTuring ()

+ (NSArray<BDDebugSectionModel *> *)feeds;

@end

BDAppAddDebugFeedFunction() {
    [BDDebugFeedTuring sharedInstance].parameterFeed = [BDDebugFeedParameterTuring feeds];
}

@implementation BDDebugFeedParameterTuring

+ (void)fakeParameterModelWithType:(NSString *)type {
    BDTuringNetworkFinishBlock callback = ^(NSData *data) {
        if (data == nil) {
            return;
        }
        NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSString *decision = [jsonObj valueForKey:@"decision_conf"];
        NSDictionary *decisionConf = [NSJSONSerialization JSONObjectWithData:[decision dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        [[BDTuringParameter sharedInstance] updateCurrentParameter:decisionConf];
        [[BDDebugFeedTuring sharedInstance].turing popVerifyViewWithCallback:^(BDTuringVerifyResult *result) {
            
        }];
    };
    NSDictionary *queryParameters = @{
        kDebugFakeType:type,
    };
    [BDTNetworkManager asyncRequestForURL:DebugFakeURL
                                   method:@"GET"
                          queryParameters:queryParameters
                           postParameters:nil
                                 callback:callback
                            callbackQueue:dispatch_get_main_queue()
                                  encrypt:NO
                                  tagType:BDTNetworkTagTypeManual];
}

+ (NSArray<BDDebugSectionModel *> *)feeds {
    NSMutableArray<BDDebugSectionModel *> *sections = [NSMutableArray new];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"透传决策示例";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"问答验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [BDDebugFeedParameterTuring fakeParameterModelWithType:@"qa"];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"滑动图片验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [BDDebugFeedParameterTuring fakeParameterModelWithType:@"slide"];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"3D点选验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [BDDebugFeedParameterTuring fakeParameterModelWithType:@"3d"];
            };
           setting;
        })];

        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"Text点选验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [BDDebugFeedParameterTuring fakeParameterModelWithType:@"text"];
            };
           setting;
        })];

        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"旋转验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [BDDebugFeedParameterTuring fakeParameterModelWithType:@"whirl"];
            };
           setting;
        })];

        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"短信上行验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [BDDebugFeedParameterTuring fakeParameterModelWithType:@"sms"];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"无障碍验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [BDDebugFeedParameterTuring fakeParameterModelWithType:@"voice"];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"Header拦截出码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [BDTNetworkManager asyncRequestForURL:DebugFakeURLHeader
                                               method:@"GET"
                                      queryParameters:nil
                                       postParameters:nil
                                             callback:^(NSData *data) {}
                                        callbackQueue:nil
                                              encrypt:NO
                                              tagType:BDTNetworkTagTypeManual];
            };
           setting;
        })];
        
        model.feeds = feeds;
        model;
    })];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"challenge code示例";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"滑块图片验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [[BDDebugFeedTuring sharedInstance].turing popPictureVerifyViewWithRegionType:BDTuringRegionTypeCN challengeCode:99999 callback:^(BDTuringVerifyStatus status, NSString * _Nullable token, NSString * _Nullable mobile) {}];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"点选图片验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [[BDDebugFeedTuring sharedInstance].turing popPictureVerifyViewWithRegionType:BDTuringRegionTypeCN challengeCode:99998 callback:^(BDTuringVerifyStatus status, NSString * _Nullable token, NSString * _Nullable mobile) {}];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"3d图片验证码";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [[BDDebugFeedTuring sharedInstance].turing popPictureVerifyViewWithRegionType:BDTuringRegionTypeCN challengeCode:99997 callback:^(BDTuringVerifyStatus status, NSString * _Nullable token, NSString * _Nullable mobile) {}];
            };
           setting;
        })];
        
        model.feeds = feeds;
        model;
    })];
    
    return sections;
}


@end

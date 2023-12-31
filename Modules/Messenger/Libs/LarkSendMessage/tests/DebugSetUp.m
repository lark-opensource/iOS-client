//
//  DebugSetUp.m
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2022/12/14.
//

#import "DebugSetUp.h"

@implementation DebugSetUp

+ (void)load {
    // 自动登陆时，需要自动消除隐私协议、启动引导
    NSUserDefaults *privacyUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"lark_storage.Global"];
    [privacyUserDefaults setValue:@(YES) forKey:@"lskv.space_Global.domain_Core_Privacy.HasShownPrivacyAlert"];
    [privacyUserDefaults synchronize];

    NSUserDefaults * guideUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"lark_storage.Global"];
    [guideUserDefaults setValue:@(YES) forKey:@"lskv.space_Global.domain_Core_LaunchGuide.show"];
    [guideUserDefaults synchronize];
}

@end

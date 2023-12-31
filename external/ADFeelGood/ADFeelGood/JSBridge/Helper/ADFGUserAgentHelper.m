//
//  ADFGUserAgentHelper.m
//  BUAdSDK
//
//  Created by cuiyanan on 2019/9/3.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "ADFGUserAgentHelper.h"
#import "ADFGCommonMacros.h"
#import <WebKit/WebKit.h>

static NSString *ADFG_UserAgent = @"ADFG_UserAgent";

@interface ADFGUserAgentHelper()
@property (nonatomic, strong) WKWebView *webview;
@property (nonatomic, copy)   NSString *ua;
@property (nonatomic, assign) BOOL updatedUa;//是否更新过
@end

@implementation ADFGUserAgentHelper
+ (instancetype)sharedInstance{
    static ADFGUserAgentHelper *uaHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uaHelper = [[ADFGUserAgentHelper alloc] init];
    });
    
    return uaHelper;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ua = [[NSUserDefaults standardUserDefaults] objectForKey:ADFG_UserAgent];
        self.updatedUa = NO;
    }
    return self;
}

- (NSString *)setup {
    NSString *ua = self.userAgent;
    return ua;
}

- (NSString *)userAgent {
    dispatch_block_t block = ^{
        if (!self.updatedUa) {
            self.updatedUa = YES;
            self.webview = [[WKWebView alloc] initWithFrame:CGRectZero];
            adfg_weakify(self)
            [self.webview evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                adfg_strongify(self)
                self.ua = result;
                if (ADFGCheckValidString(self.ua)) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [[NSUserDefaults standardUserDefaults] setObject:self.ua forKey:ADFG_UserAgent];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    });
                }
            }];
        }
    };
    if ([[NSThread currentThread] isMainThread]) {
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), block);
    }
    return self.ua;
}


@end

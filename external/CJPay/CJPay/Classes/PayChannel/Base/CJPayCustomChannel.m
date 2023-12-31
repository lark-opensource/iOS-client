//
//  CJPayCustomChannel.m
//  CJPay
//
//  Created by 王新华 on 8/16/19.
//

#import "CJPayCustomChannel.h"
#import "CJPayChannelManager.h"
#import "CJPaySDKMacro.h"

@interface CJPayCustomChannel()

@property (nonatomic, copy) NSString *scheme;
@property (nonatomic, assign) BOOL wakingApp;

@end

@implementation CJPayCustomChannel

CJPAY_REGISTER_PLUGIN({
    [[CJPayChannelManager sharedInstance] registerChannelClass:self channelType:CJPayChannelTypeCustom];
})

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)canProcessWithURL:(NSURL *)URL {
    if ([URL.absoluteString hasPrefix:self.scheme]) {
        CJ_CALL_BLOCK(self.completionBlock, CJPayChannelTypeCustom, CJPayResultTypeSuccess, @"");
        self.completionBlock = nil;
        self.dataDict = nil;
        return YES;
    } else {
        return NO;
    }
}

- (void)payActionWithDataDict:(NSDictionary *)dataDict completionBlock:(CJPayCompletion)completionBlock {
    [super payActionWithDataDict:dataDict completionBlock:completionBlock];
    
    self.scheme = [dataDict cj_stringValueForKey:@"refer"] ?: [CJPayChannelManager sharedInstance].h5PayReferUrl;
    
    self.wakingApp = YES;
}

- (void)appWillEnterForeground {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.wakingApp) {
            self.wakingApp = NO;
            CJ_CALL_BLOCK(self.completionBlock, self.channelType, CJPayResultTypeBackToForeground, @"");
        }
    });
}

@end

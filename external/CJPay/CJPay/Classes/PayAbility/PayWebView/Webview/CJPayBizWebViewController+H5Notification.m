//
//  CJPayBizWebViewController+H5Notification.m
//  CJPay
//
//  Created by liyu on 2020/1/16.
//

#import "CJPayBizWebViewController+H5Notification.h"

#import <TTBridgeUnify/TTWebViewBridgeEngine.h>
#import <objc/runtime.h>
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayWKWebView.h"
#import "CJPayBaseHybridWebview.h"

@implementation CJPayBizWebViewController (H5Notification)

- (void)registerH5Notification
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(H5CallNotification:)
                                               name:kH5CommunicationNotification
                                             object:nil];
    @CJWeakify(self)
    self.ttcjpayLifeCycleBlock = ^(CJPayVCLifeType type) {
        @CJStrongify(self);
        if (type == CJPayVCLifeTypeWillAppear) {
            if (self.dataSentByH5 == nil) {
                return;
            }
            [weak_self sendEvent:@"ttcjpay.receiveSDKNotification" params:weak_self.dataSentByH5];
            weak_self.dataSentByH5 = nil;
        }
    };
}

- (NSDictionary *)dataSentByH5
{
    return objc_getAssociatedObject(self, @selector(dataSentByH5));
}

- (void)setDataSentByH5:(NSDictionary *)dataSentByH5
{
    objc_setAssociatedObject(self, @selector(dataSentByH5), dataSentByH5, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)H5CallNotification:(NSNotification *)note
{
    self.dataSentByH5 = note.object;
}

@end

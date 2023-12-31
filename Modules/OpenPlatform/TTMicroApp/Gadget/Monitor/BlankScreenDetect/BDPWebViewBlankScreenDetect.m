//
//  BDPWebViewBlankScreenDetect.m
//  Timor
//
//  Created by 刘春喜 on 2019/11/21.
//

#import "BDPWebViewBlankScreenDetect.h"
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/EMAFeatureGating.h>
#import "BDPAppPage.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/EEFeatureGating.h>

@implementation BDPWebViewBlankScreenDetect
/*
+ (void)detectBlankWebView:(WKWebView *)webView complete:(void (^)(BDPBlankDetectModel *, NSError * _Nullable))complete {
 */
//  未修改任何逻辑，只是显式的补充了_Nullable和BDPAppPage类型
+ (void)detectBlankWebView:(BDPAppPage * _Nullable)webView complete:(void (^)(BDPBlankDetectModel * _Nullable, NSError * _Nullable))complete {
    if (!complete) {
        return;
    }

    [GadgetBlankDetect detectBlankWithWebview:webView complete:complete];
}

+ (NSError *)errorWithDetectStatus:(BDPDetectBlankError)detectStatus {
    NSDictionary *userInfo = nil;
    switch (detectStatus) {
        case BDPDetectBlankImageError:
            userInfo = @{NSLocalizedDescriptionKey:@"can not get image"};
            break;
            
        case BDPDetectBlankNotSupportError:
            userInfo = @{NSLocalizedDescriptionKey:@"not support detect"};
            break;
        case BDPDetectBlankResultNull:
            userInfo = @{NSLocalizedDescriptionKey:@"result is null"};
            break;
        default:
            userInfo = @{NSLocalizedDescriptionKey:@"other error"};
            break;
    }
    
    return [NSError errorWithDomain:@"BDPWebViewBlankDetect" code:detectStatus userInfo:userInfo];
}

@end

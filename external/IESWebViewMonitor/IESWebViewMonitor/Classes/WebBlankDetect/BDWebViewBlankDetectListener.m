//
//  BDWebViewBlankDetectListener.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/5/21.
//

#import "BDWebViewBlankDetectListener.h"
#import <BDWebKit/BDWebViewBlankDetect.h>
#import "IESLiveWebViewPerformanceDictionary.h"
#import "BDWebView+BDWebViewMonitor.h"

#define STRING_NOT_EMPTY(str) (str?str:@"")

@interface BDWebViewBlankDetectListener () <BDWebViewBlankDetectListenerDelegate>

@property (nonatomic, strong) NSString *testString;

@end

@implementation BDWebViewBlankDetectListener

+ (BOOL)startMonitorWithClasses:(NSSet *)classes setting:(NSDictionary *)setting {
    BDWebViewBlankDetectListener *listener = [[BDWebViewBlankDetectListener alloc] init];
    [BDWebViewBlankDetect addBlankDetectMonitorListener:listener];
    return YES;
}

#pragma mark BDWebViewBlankDetectListenerDelegate

- (void)onDetectResult:(UIView *)webView isBlank:(BOOL)isBlank detectType:(BDDetectBlankMethod)detectType detectImage:(UIImage *)image error:(NSError *)error costTime:(NSInteger)costTime {
    if (!webView || ![webView isKindOfClass:WKWebView.class]) {
        return;
    }
    
    if ([(WKWebView *)webView bdwm_disableMonitor]) {
        return;
    }

    if (!image) { return; }
    // 宽高为0 不检测并上报~
    if (image.size.width < 0.0001 || image.size.height < 0.0001) { return; }
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"event_type":@"blank",
        @"is_blank":@(isBlank?1:0),
        @"detect_type":@(detectType),
        @"cost_time":@(costTime)
    }];
    if (error) {
        [info setValue:@(error.code) forKey:@"error_code"];
        [info setValue:[NSString stringWithFormat:@"Domain:%@ , info:%@" , STRING_NOT_EMPTY(error.domain),STRING_NOT_EMPTY(error.localizedDescription)] forKey:@"error_msg"];
    }
    
    IESLiveWebViewPerformanceDictionary *performanceDic = [(WKWebView *)webView performanceDic];
    [performanceDic reportDirectlyWrapNativeInfoWithDic:info];
}

@end

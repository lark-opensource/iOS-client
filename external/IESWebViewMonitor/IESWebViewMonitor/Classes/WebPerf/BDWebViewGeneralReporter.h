//
//  IESLiveWebViewGeneralMonitor.h
//  IESWebViewMonitor
//
//  Created by 蔡腾远 on 2020/1/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define IESWebViewDelegateSafeCallORIG(slf, code) \
Class lastCallClass = [slf lastCallClass]; \
Class methodCls = [BDWebViewGeneralReporter getTargetDelegateClass:slf]; \
Class curCls = [slf lastCallClass] ?: [BDWebViewGeneralReporter getTargetDelegateClass:slf]; \
code \
curCls = nil; \
methodCls = nil; \
[slf setLastCallClass:lastCallClass];

@class WKWebView;
@class IESLiveWebViewPerformanceDictionary;
typedef NS_ENUM (NSInteger, BDWebViewGeneralType) {
    BDWebViewInitType, // time that webview was initted
    BDWebViewAttachType, // time that webview was added
    BDWebViewDettachType, // time that webview was remove
    BDRequestStartType,
    BDRequestFailType,
    BDRedirectStartType,
    BDNavigationStartType,
    BDNavigationPreFinishType,
    BDNavigationFinishType,
    BDNavigationFailType,
    BDNavigationTerminateType,
    BDNavigationResponseType
};

@interface BDWebViewGeneralReporter : NSObject

@property (nonatomic, strong, class) NSMutableDictionary<Class, NSMutableDictionary<NSString*, NSValue*>*> *ORIGImpDic;
@property (nonatomic, strong, class) NSMutableDictionary<Class, NSPointerArray*> *insertedDelegateIMPs;

#pragma mark - public Api
+ (Class)getTargetDelegateClass:(NSObject *)delegate;

+ (Class)bdwm_hookClass:(NSObject *)obj error:(NSError **)error;

#pragma mark - ORIGImpDic & insertedDelegateIMPs
+ (void)prepareForClass:(Class)cls;

+ (void)prepareORIGForClass:(Class)cls;

+ (NSPointerArray *)getDelegateIMPs:(Class)cls;

/**WKWebView 信息上报*/
+ (void)updateMonitorOfWKWebView:(WKWebView *)webView
                      statusCode:(NSNumber * __nullable)statusCode
                           error:(NSError * __nullable)error
                        withType:(BDWebViewGeneralType)type;

@end

NS_ASSUME_NONNULL_END

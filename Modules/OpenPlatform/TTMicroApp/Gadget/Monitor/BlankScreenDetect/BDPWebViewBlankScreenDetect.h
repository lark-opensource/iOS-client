//
//  BDPWebViewBlankScreenDetect.h
//  Timor
//
//  Created by 刘春喜 on 2019/11/21.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "BDPBlankDetectModel.h"

@class BDPAppPage;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDPDetectBlankError) {
    BDPDetectBlankImageError = 1, //生成图片失败
    BDPDetectBlankNotSupportError, //iOS 11以下不支持检测
    BDPDetectBlankResultNull,
    BDPDetectBlankOtherError
};

@protocol BDPWebViewBlankScreenDetectInterface <NSObject>
/*
+ (void)detectBlankWebView:(WKWebView *)webView complete:(void (^)(BDPBlankDetectModel *, NSError * _Nullable))complete;
 */
//  未修改任何逻辑，只是显式的补充了_Nullable和BDPAppPage类型
+ (void)detectBlankWebView:(BDPAppPage * _Nullable)webView complete:(void (^)(BDPBlankDetectModel * _Nullable, NSError * _Nullable))complete;
@end

@interface BDPWebViewBlankScreenDetect : NSObject <BDPWebViewBlankScreenDetectInterface>

@end

NS_ASSUME_NONNULL_END

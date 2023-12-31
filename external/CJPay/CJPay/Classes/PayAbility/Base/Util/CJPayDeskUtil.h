//
//  CJPayDeskUtil.h
//  CJPay
//
//  Created by wangxiaohong on 2022/12/27.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"
#import "CJPayDeskRouteDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDeskUtil : NSObject

+ (void)openLynxPageBySchema:(NSString *)schema
             completionBlock:(void (^)(CJPayAPIBaseResponse * _Nullable))completion;

+ (void)openLynxPageBySchema:(NSString *)schema
               routeDelegate:(id<CJPayDeskRouteDelegate> _Nullable)routeDelegate
             completionBlock:(void (^)(CJPayAPIBaseResponse * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END

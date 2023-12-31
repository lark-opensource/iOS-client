//
//  CJPayUniversalPayDeskService.h
//  Pods
//
//  Created by 王新华 on 2020/11/21.
//

#ifndef CJPayUniversalPayDeskService_h
#define CJPayUniversalPayDeskService_h
#import "CJPaySDKDefine.h"
#import "CJPayDeskRouteDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayUniversalPayDeskService<NSObject>

- (void)i_openUniversalPayDeskWithParams:(NSDictionary *)params withDelegate:(nullable id<CJPayAPIDelegate>)delegate;
- (void)i_openUniversalPayDeskWithParams:(NSDictionary *)params referVC:(UIViewController *)referVC withDelegate:(id<CJPayAPIDelegate>)delegate;
- (void)i_openUniversalPayDeskWithParams:(NSDictionary *)params routeDelegate:(id<CJPayDeskRouteDelegate>)routeDelegate withDelegate:(nullable id<CJPayAPIDelegate>)delegate;
- (void)i_openUniversalPayDeskWithParams:(NSDictionary *)params referVC:(UIViewController *)referVC routeDelegate:(id<CJPayDeskRouteDelegate>)routeDelegate withDelegate:(id<CJPayAPIDelegate>)delegate;
- (void)i_callBackWithCallBackId:(NSString *)callBackId
                        response:(CJPayAPIBaseResponse *)response;
- (NSDictionary *)i_processCallbackDataWithResponse:(CJPayAPIBaseResponse *)response;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayUniversalPayDeskService_h */

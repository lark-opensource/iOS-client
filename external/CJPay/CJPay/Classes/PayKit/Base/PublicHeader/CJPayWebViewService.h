//
//  CJPayWebViewService.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/16.
//

#ifndef CJPayWebViewService_h
#define CJPayWebViewService_h

#import "CJPayProtocolServiceHeader.h"
#import "CJBizWebDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayWebViewService <CJPayWakeBySchemeProtocol>

- (void)i_openScheme:(NSString *)scheme withDelegate:(id<CJPayAPIDelegate>)delegate;
- (void)i_openScheme:(NSString *)scheme callBack:(nullable void(^)(CJPayAPIBaseResponse *nullable))callback;
- (void)i_openSchemeByNtvVC:(NSString *)scheme fromVC:(UIViewController *)fromVC withInfo:(NSDictionary *)sdkInfo withDelegate:(id<CJPayAPIDelegate>)delegate;
- (void)i_registerBizDelegate:(id<CJBizWebDelegate>)delegate;
- (void)i_openCjSchemaByHost:(NSString *)schemaStr;
- (void)i_openCjSchemaByHost:(NSString *)schemaStr fromVC:(UIViewController *)referVC useModal:(BOOL)useModal;
- (void)i_gotoIMServiceWithAppID:(NSString *)appID fromVC:(UIViewController *)fromVC;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayWebViewService_h */

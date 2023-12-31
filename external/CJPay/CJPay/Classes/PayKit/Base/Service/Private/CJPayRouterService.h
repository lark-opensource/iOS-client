//
//  CJPayRouterService.h
//  Pods
//
//  Created by 王新华 on 2020/11/15.
//

#ifndef CJPayRouterService_h
#define CJPayRouterService_h
#import "CJPaySDKDefine.h"


NS_ASSUME_NONNULL_BEGIN

extern NSString *const CJPayRouterParameterURL;
extern NSString *const CJPayRouterParameterCompletion;
extern NSString *const CJPayRouterParameterUserInfo;

@protocol CJPayRouterService <NSObject>

// SDK 内部路由协议
- (BOOL)i_openScheme:(NSString *)scheme withDelegate:(nullable id<CJPayAPIDelegate>)delegate;

- (BOOL)i_openScheme:(NSString *)scheme callBack:(void (^)(CJPayAPIBaseResponse *))callback;

@end


NS_ASSUME_NONNULL_END

#endif /* CJPayRouterService_h */

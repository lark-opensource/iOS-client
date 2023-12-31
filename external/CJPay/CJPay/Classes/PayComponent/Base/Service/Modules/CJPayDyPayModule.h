//
//  CJPayDyPayModule.h
//  Pods
//
//  Created by xutianxi on 2022/9/22.
//

#import <Foundation/Foundation.h>
#import "CJPayProtocolServiceHeader.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayDyPayModule

// 打开追光收银台界面，params是由商户传入的参数
- (void)i_openDyPayDeskWithParams:(nonnull NSDictionary *)params delegate:(nullable id<CJPayAPIDelegate>)delegate;

// 在打开追光收银台界面前，提前发网络请求，带缓存功能
- (void)i_requestCreateOrderBeforeOpenDyPayDeskWith:(nonnull NSDictionary *)params completion:(void(^)(NSError * _Nullable error, NSDictionary * _Nullable response))completion;

@end

NS_ASSUME_NONNULL_END

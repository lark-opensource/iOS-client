//
//  CJPayOuterModule.h
//  Aweme
//
//  Created by wangxiaohong on 2022/10/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayOuterModule <NSObject>

// 打开唤端聚合收银台界面，schemaParams是由商户传入的参数
- (void)i_openOuterDeskWithSchemaParams:(nonnull NSDictionary *)schemaParams withDelegate:(nullable id<CJPayAPIDelegate>)delegate;

// 在打开唤端聚合收银台界面前，提前发网络请求，带缓存功能
- (void)i_requestCreateOrderBeforeOpenBytePayDeskWith:(nonnull NSDictionary *)schemaParams completion:(void(^)(NSError * _Nonnull error, NSDictionary * _Nonnull response))completion;

@end

NS_ASSUME_NONNULL_END

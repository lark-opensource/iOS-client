//
//  FLTMethodManager.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/6.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDFLTBResponseProtocol.h"
#import "BDMethodAuthProtocol.h"

typedef void(^AnonymousFunction)(NSString *methodName, NSDictionary *arguments, FLTBResponseCallback callback);

NS_ASSUME_NONNULL_BEGIN

@interface BDFlutterMethodManager : NSObject

+ (instancetype)sharedManager;

//为特定的bridge方法注册类实现
- (void)registClass:(Class)className forName:(NSString *)name;

//为特定的bridge方法注册实例实现
- (void)registMethod:(id<BDBridgeMethod>)method forName:(NSString *)name;

//hook对应的bridge实现
- (void)hookMethod:(id<BDBridgeMethod>)method forName:(NSString *)name;

//注册匿名实现执行对应的bridgeCall
- (void)registFunction:(AnonymousFunction)fuc forName:(NSString *)name;

//获取已经注册的bridge实例
- (id<BDBridgeMethod>)registedMethodInstanceForName:(NSString *)name;

//删除已经注册的bridge
- (void)cancelRegistName:(NSString *)name;

//为bridge调用添加授权
- (void)addAuthenticator:(id<BDMethodAuth>)authenticator;

//取消授权调用
- (void)removeAuthenticator:(id<BDMethodAuth>)authenticator;

//调用bridge方法
- (void)callMethod:(NSString *)name argument:(id)argument callback:(FLTBResponseCallback)callback inContext:(id<BDBridgeContext>)context;

@end

NS_ASSUME_NONNULL_END

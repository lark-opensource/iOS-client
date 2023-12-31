//
//  TMAPluginCustomImplRegister.h
//  Article
//
//  Created by zhangkun on 07/08/2018.
//

#import <Foundation/Foundation.h>
#import <OPPluginManagerAdapter/BDPJSBridgeBase.h>

@interface TMAPluginCustomImplRegister : NSObject

+ (instancetype)sharedInstance;

/// 应用Plugin的默认Method的自定义实现.（请在非+load的其他的合适的时机调用，例如引擎初始化的时候）
- (void)applyAllCustomPlugin;

/// 该注册方法会覆盖掉Plugin的默认Method实现
- (void)registerInstanceMethod:(NSString *)method isSynchronize:(BOOL)isSynchronize isOnMainThread:(BOOL)isOnMainThread class:(Class)class type:(BDPJSBridgeMethodType)type;

@end

//
//  DYOpenAppDelegateInternalBridge.h
//  DouyinOpenPlatformSDK
//
//  Created by ByteDance on 2022/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DYOpenAppDelegateInternalBridge <NSObject>

@optional
/// @brief 启动后的一些处理
/// @param application launchOptions
/// @param launchOptions launchOptions
- (void)internal_application:(UIApplication *_Nullable)application didFinishLaunchingWithOptions:(NSDictionary *_Nullable)launchOptions;

/// @brief 开启 ticket guard
/// @param enableTicketGuard 是否开启
- (void)internal_setEnableTicketGuard:(BOOL)enableTicketGuard;

/// @brief get settings
/// @param key key string
- (id _Nullable)internal_settingsObjectForKey:(NSString *_Nonnull)key defaultValue:(id _Nullable)defaultValue;

@end

NS_ASSUME_NONNULL_END

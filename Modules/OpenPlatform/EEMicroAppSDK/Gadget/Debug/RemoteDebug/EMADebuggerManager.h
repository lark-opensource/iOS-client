//
//  EMADebuggerManager.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import <Foundation/Foundation.h>
#import <TTMicroApp/EMADebuggerSharedService.h>

NS_ASSUME_NONNULL_BEGIN

/// 支持同时跑多个应用
@interface EMADebuggerManager : NSObject <EMADebuggerSharedService>

+ (instancetype)sharedInstance;

/// 服务是否已开启
@property (nonatomic, assign, readonly) BOOL serviceEnable;

/// 处理 wsURL 调用
- (void)handleDebuggerWSURL:(NSString * _Nonnull)wsURL;

/// 在启动 App 之前建立 Debugger 连接
- (void)connectAppDebuggerForUniqueID:(BDPUniqueID * _Nonnull)uniqueID completion:(void (^ _Nullable)(BOOL success))completion;

/// 推送命令
- (void)pushCmd:(EMADebuggerCommand * _Nonnull)cmd forUniqueID:(BDPUniqueID * _Nonnull)uniqueID;

@end

NS_ASSUME_NONNULL_END

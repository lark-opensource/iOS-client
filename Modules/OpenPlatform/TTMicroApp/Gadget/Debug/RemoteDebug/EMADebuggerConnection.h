//
//  EMADebuggerConnection.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import <Foundation/Foundation.h>
#import "EMADebuggerCommand.h"
#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EMADebuggerConnectionStatus) {
    EMADebuggerConnectionStatusDisconnected, // 未连接
    EMADebuggerConnectionStatusConnecting,   // 连接中
    EMADebuggerConnectionStatusConnected,    // 已连接
};

@interface EMADebuggerConnection : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *url;
@property (nonatomic, assign, readonly) EMADebuggerConnectionStatus status;

- (instancetype)initWithUrl:(NSString * _Nonnull)url uniqueID:(BDPUniqueID * _Nonnull)uniqueID;

- (void)connectWithCompletion:(void (^ _Nullable)(BOOL success))completion;
- (void)disconnect;

- (BOOL)pushCmd:(EMADebuggerCommand * _Nonnull)cmd;

/**
 设置连接的 meta 信息
 @param appName app名
 */
- (void)setMetaInfo:(NSString *)appName;

@end

NS_ASSUME_NONNULL_END

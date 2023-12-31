//
//  TMASessionManager.h
//  Timor
//
//  Created by CsoWhy on 2018/8/21.
//

#import <Foundation/Foundation.h>
#import "BDPSandboxProtocol.h"

// TMASessionManager代理协议
@protocol TMASessionManagerDelegate <NSObject>
@optional
// session 更新的方法
- (void)sessionUpdated:(NSString * _Nullable)session;
@end

@interface TMASessionManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)getSession:(id<BDPSandboxProtocol> )sandbox;
- (void)updateSession:(NSString *)session sandbox:(id<BDPSandboxProtocol> )sandbox;

- (NSString *)getAnonymousID;
- (void)updateAnonymousID:(NSString *)anonymousID;
// 增加TMASessionManager的多播delegate
- (void)addDelegate:(id<TMASessionManagerDelegate>)delegate sandbox:(id<BDPSandboxProtocol>)sandbox;
// 移除delegate
- (void)removeDelegate:(id<TMASessionManagerDelegate>)delegate;
@end

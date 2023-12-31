//
//  BulletAssembler.h
//  Pods
//
//  Created by wangxiang on 2021/4/6.
//

#ifndef BulletAssembler_h
#define BulletAssembler_h

#import <BDXServiceCenter/BDXLynxKitProtocol.h>
#import <BDXServiceCenter/BDXViewContainerProtocol.h>

@interface BulletAssembler
#if __has_include(<Lynx/LynxDebugger.h>)
    : NSObject <BDXLynxDevtoolProtocol>

- (BOOL)enableLynxDevtool:(NSURL *)url withOptions:(NSDictionary *)options;
#endif

+ (instancetype)shareInstance;

- (void)setup;

- (void)registerBridgeProvider:(Class)bridgeProvider withBid:(NSString *)bid;

@end
#endif /* BulletAssembler_h */

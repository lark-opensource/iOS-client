//
//  BDPAppContext.h
//  OPFoundation
//
//  Created by justin on 2022/12/22.
//

#import <Foundation/Foundation.h>
#import "OPJSEngineProtocol.h"
#import <ECOProbe/OPTrace.h>
#import "BDPJSBridgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN
/// FROM : BDPWebAppEngine.h
/// 通用的应用上下文，放在这里不合理
@interface BDPAppContext : NSObject<BDPContextProtocol>

@property (nonatomic, weak, nullable) id<BDPEngineProtocol> engine;
@property (nonatomic, weak, nullable) UIViewController *controller;
@property (nonatomic, weak, nullable) id<BDPEngineProtocol> workerEngine;

- (OPTrace * _Nonnull)getTrace;

@end

NS_ASSUME_NONNULL_END

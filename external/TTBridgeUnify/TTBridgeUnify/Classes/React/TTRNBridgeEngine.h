//
//  TTRNBridgeEngine.h
//  BridgeUnifyDemo
//
//  Created by lizhuopeng on 2018/11/6.
//  Copyright © 2018 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTBridgeEngine.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface TTRNBridgeEngine : RCTEventEmitter<TTBridgeEngine, RCTBridgeModule>

@property (nonatomic, weak) UIViewController *sourceController;
@property (nonatomic, strong, readonly) NSURL *sourceURL;
@property (nonatomic, weak, readonly) NSObject *sourceObject;
@property (nonatomic, strong) id<TTBridgeAuthorization> authorization;
@property(nonatomic, strong, readonly) TTBridgeRegister *bridgeRegister;

@end

@interface RCTBridge (TTRNBridgeEngine)

@property (nonatomic, strong, readonly) TTRNBridgeEngine *tt_engine;

@end


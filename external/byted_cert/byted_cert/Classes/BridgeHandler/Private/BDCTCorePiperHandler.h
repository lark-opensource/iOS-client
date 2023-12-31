//
//  BytedCertCorePiperHandler.h
//  BytedCertDemo
//
//  Created by LiuChundian on 2019/6/2.
//  Copyright © 2019年 Bytedance Inc. All rights reserved.
//

#ifndef BytedCertCorePiperHandler_h
#define BytedCertCorePiperHandler_h

#import "BytedCertDefine.h"
#import "BDCTFlow.h"
#import "BDCTPiperHandlerProtocol.h"
#import "BytedCertError.h"
#import "BytedCertInterface.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

@class BDCTAPIService, BDCTImageManager, BDCTCorePiperHandler;


@interface BDCTCorePiperHandler : NSObject <BDCTPiperHandlerProtocol>

@property (nonatomic, weak) BDCTFlow *flow;

@property (nonatomic, strong, readonly) BDCTImageManager *imageManager;

- (void)registeJSBWithName:(NSString *)name handler:(TTBridgeHandler)handler;

+ (NSDictionary *)jsbCallbackResultWithParams:(NSDictionary *)data error:(BytedCertError *)error;

- (void)fireEvent:(TTBridgeName)eventName params:(NSDictionary *)params;

@end

#endif /* BytedCertCorePiperHandler_h */

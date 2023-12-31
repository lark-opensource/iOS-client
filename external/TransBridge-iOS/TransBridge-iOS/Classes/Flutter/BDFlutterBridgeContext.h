//
//  FLTBridgeContext.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/7.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDBridgeContextProtocol.h"
#import "BDFlutterProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDFlutterBridgeContext : NSObject <BDBridgeContext>

- (instancetype)initWithMessage:(NSObject *)messager;

- (void)sendEvent:(NSString *)name data:(id)data;

@end

NS_ASSUME_NONNULL_END

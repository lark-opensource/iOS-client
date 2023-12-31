//
//  FlutterBridgeHost.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDBridgeHost.h"
#import "BDFlutterProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDFlutterBridgeHost : BDBridgeHost

- (instancetype)initWithCarrier:(NSObject *)carrier
                  methodChannel:(id<FLTBMethodChannel>)channel;

@end

NS_ASSUME_NONNULL_END

//
//  BridgeMethodProtocol.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/7.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDFlutterProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDBridgeMethod <NSObject>

@optional
- (void)call:(NSDictionary *)argument callback:(FLTBResponseCallback)callback;

@end

NS_ASSUME_NONNULL_END

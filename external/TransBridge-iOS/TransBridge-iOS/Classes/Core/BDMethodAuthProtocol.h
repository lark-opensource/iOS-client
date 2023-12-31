//
//  IBridgeAuth.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/6.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDFLTBResponseProtocol.h"
#import "BDBridgeContextProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDMethodAuth <NSObject>

- (BOOL)isAuthorizedMethod:(id<BDBridgeMethod>)method inContext:(id<BDBridgeContext>)context;

@end

NS_ASSUME_NONNULL_END

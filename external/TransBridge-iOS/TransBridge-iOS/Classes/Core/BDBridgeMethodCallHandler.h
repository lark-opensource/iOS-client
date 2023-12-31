//
//  BridgeMethodCallHandler.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/5.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDFlutterProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDBridgeCall <NSObject>

- (void)call:(NSString *)name arguments:(id)arguments forMessager:(NSObject *)messenger completion:(FLTBResponseCallback)completion;

@end

@interface BDBridgeMethodCallHandler : NSObject <BDBridgeCall>

- (instancetype)initWithBridgeCall:(id<BDBridgeCall>)bridge onHostView:(UIView *)host;

@end

NS_ASSUME_NONNULL_END

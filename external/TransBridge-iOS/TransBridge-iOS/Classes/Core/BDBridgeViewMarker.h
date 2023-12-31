//
//  BridgeViewMarker.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/7.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDBridgeViewMarker : NSObject

+ (NSInteger)getBridgeId:(NSObject *)view;

+ (NSInteger)generateBridgeIfNeed:(NSObject *)view;

@end

NS_ASSUME_NONNULL_END

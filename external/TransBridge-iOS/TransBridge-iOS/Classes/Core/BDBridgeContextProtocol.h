//
//  BridgeContext.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/3.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDMethodProtocol.h"

typedef NS_ENUM(NSInteger, BridgeContextType) {
  BridgeContextTypeJS,
  BridgeContextTypeRN,
  BridgeContextTypeFlutter,
};

NS_ASSUME_NONNULL_BEGIN

@protocol BDBridgeContext <NSObject>

- (BridgeContextType)contextType;

- (NSObject *)messager;


@end

NS_ASSUME_NONNULL_END

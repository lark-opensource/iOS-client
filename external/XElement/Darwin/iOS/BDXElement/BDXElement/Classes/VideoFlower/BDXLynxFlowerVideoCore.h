// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "BDXLynxFlowerVideoPlayerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxFlowerVideoCore : NSObject <BDXLynxFlowerVideoCorePlayerProtocol>

@property(nonatomic, strong) BDXLynxFlowerVideoPlayerConfiguration *configuration;
@property(nonatomic, copy) NSDictionary *logExtraDict;
@property(nonatomic, assign) NSTimeInterval actionTimestamp;

@end

NS_ASSUME_NONNULL_END

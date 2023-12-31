//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

@class LynxContext;
NS_ASSUME_NONNULL_BEGIN
@interface LynxServiceInfo : NSObject

@property(nonatomic, weak) LynxContext *context;
@property(nonatomic, strong) NSDictionary *extra;

@end

NS_ASSUME_NONNULL_END

//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LynxUIReportInfoDelegate <NSObject>

- (NSDictionary*)reportUserInfoOnError;

@end

NS_ASSUME_NONNULL_END

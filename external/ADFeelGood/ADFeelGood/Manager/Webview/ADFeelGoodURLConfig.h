//
//  ADFeelGoodURLConfig.h
//  FeelGoodDemo
//
//  Created by bytedance on 2020/8/26.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADFeelGoodURLConfig : NSObject
+ (nonnull NSString *)baseURLWithChannel:(nonnull NSString *)channel;
+ (nonnull NSString *)checkURLWithChannel:(nonnull NSString *)channel;
+ (nonnull NSString *)headerOriginURLWithChannel:(nonnull NSString *)channel;
@end

NS_ASSUME_NONNULL_END

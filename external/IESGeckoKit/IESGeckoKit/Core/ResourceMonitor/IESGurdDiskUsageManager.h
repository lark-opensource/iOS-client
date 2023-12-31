//
//  IESGurdDiskUsageManager.h
//  IESGeckoKit
//
//  Created by 黄李磊 on 2021/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdDiskUsageManager : NSObject

+ (instancetype)sharedInstance;

- (void)recordUsageIfNeeded;

@end

NS_ASSUME_NONNULL_END

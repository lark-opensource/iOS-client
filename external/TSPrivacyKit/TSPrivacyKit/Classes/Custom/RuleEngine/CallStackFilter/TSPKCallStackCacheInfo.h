//
//  TSPKCallStackCacheInfo.h
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import <Foundation/Foundation.h>

@interface TSPKCallStackCacheInfo : NSObject

+ (nonnull instancetype)sharedInstance;

- (nullable NSDictionary *)loadWithVersion:(nonnull NSString *)ver;

- (void)save:(nonnull NSDictionary *)info forVersion:(nonnull NSString *)ver;

@end

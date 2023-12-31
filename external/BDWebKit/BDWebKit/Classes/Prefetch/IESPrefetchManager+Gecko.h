//
//  IESPrefetchManager+Gecko.h
//  BDWebKit
//
//  Created by Hao Wang on 2020/3/16.
//

#import <IESPrefetch/IESPrefetch.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchManager (Gecko)

- (void)bindGeckoAccessKey:(NSString *)accessKey channels:(NSArray<NSString *> *)channels forBusiness:(NSString *)business;

@end

NS_ASSUME_NONNULL_END

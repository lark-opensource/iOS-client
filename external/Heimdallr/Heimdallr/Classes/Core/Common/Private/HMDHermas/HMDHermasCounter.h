//
//  HMDHermasCounter.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 27/5/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDHermasCounter : NSObject

+ (instancetype)shared;

- (instancetype)init NS_UNAVAILABLE;

- (unsigned long long)generateSequenceCode:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

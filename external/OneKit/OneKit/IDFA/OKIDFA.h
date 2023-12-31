//
//  OKIDFA.h
//  OneKit
//
//  Created by bob on 2021/1/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OKIDFA : NSObject

+ (instancetype)sharedInstance;

- (nullable NSString *)IDFA;

@end

NS_ASSUME_NONNULL_END

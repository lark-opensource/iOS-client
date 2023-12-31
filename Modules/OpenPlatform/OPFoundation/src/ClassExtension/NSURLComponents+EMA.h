//
//  NSURLComponents+EMA.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/8/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLComponents (EMA)

@property (nullable, copy, readonly) NSDictionary<NSString *, NSString *> *ema_queryItems;

- (void)setQueryItemWithKey:(NSString * _Nonnull)key value:(NSString * _Nullable)value;

@end

NS_ASSUME_NONNULL_END

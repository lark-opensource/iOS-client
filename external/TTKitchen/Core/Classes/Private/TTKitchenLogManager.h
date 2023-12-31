//
//  TTKitchenLog.h
//  TTKitchen-Browser-Core-SettingsSyncer
//
//  Created by Peng Zhou on 2020/4/23.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface TTKitchenLogManager : NSObject

@property (nonatomic, assign) NSUInteger maxLogCount;

+ (instancetype)sharedInstance;

- (NSDictionary<NSString*, NSDictionary *> *)getLog;

// 在Kitchen更新之后异步记录当前的Kitchen作为一个Log Entry
- (void)addCurrentLogEntry:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END

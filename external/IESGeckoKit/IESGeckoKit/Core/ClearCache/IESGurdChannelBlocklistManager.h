
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdChannelBlocklistManager : NSObject

+ (instancetype)sharedManager;

- (void)addChannel:(NSString *)channel forAccessKey:(NSString *)accessKey;

- (void)removeChannel:(NSString *)channel forAccessKey:(NSString *)accessKey;

- (BOOL)isBlocklistChannel:(NSString *)channel accessKey:(NSString *)accessKey;

- (NSUInteger)getBlocklistCount:(NSString *)accessKey;

- (NSDictionary<NSString *, NSArray<NSString *> *> *)copyBlocklistChannel;

- (void)cleanCache;

@end

NS_ASSUME_NONNULL_END

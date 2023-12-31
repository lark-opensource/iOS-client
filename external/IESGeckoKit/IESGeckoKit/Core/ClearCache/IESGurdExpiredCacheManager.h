#import <Foundation/Foundation.h>
#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdExpiredCacheManager : NSObject

// 是否启用清理
@property (nonatomic, assign) BOOL clearExpiredCacheEnabled;

// 目标清理Group
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *targetGroupDictionary;

// 清理补偿下发normal组channel list
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *targetChannelDictionary;

+ (instancetype)sharedManager;

- (void)updateTargetGroupDictionary:(NSDictionary<NSString *, NSString *> *)targetGroupDictionary;

- (void)updateTargetChannels:(NSDictionary<NSString *, NSArray<NSString *> *> *)targetChannels;

// 获取过期清理资源大小
- (int64_t)getClearCacheSize:(int)expireAge;

// 获取对应 accessKey 过期清理资源大小
- (int64_t)getClearCacheSizeWithAccesskey:(NSString *)accessKey
                                expireAge:(int)expireAge;

// 删除全部过期 channels
- (void)clearCache:(int)expireAge
         cleanType:(int)cleanType
        completion:(void (^ _Nullable)(NSDictionary<NSString *, IESGurdSyncStatusDict> *info))completion;

// 删除对应 accesskey 的过期 channels
- (void)clearCacheWithAccesskey:(NSString *)accessKey
                      expireAge:(int)expireAge
                      cleanType:(int)cleanType
                     completion:(void (^ _Nullable)(IESGurdSyncStatusDict info))completion;

- (void)clearCacheWhenLowStorage;

@end

NS_ASSUME_NONNULL_END

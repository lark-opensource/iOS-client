//
// JATNetworkOpt.h
// 
//
// Created by Aircode on 2022/8/3

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, JATNetworkOptType) {
    JATNetworkOptTypeNone = 0,
    JATNetworkOptTypeTTNetBuidJsonMethodToSubThread,
};

@interface JATNetworkOpt : NSObject

@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, assign, readonly) NSUInteger currentOptType;

+ (instancetype)shared;

/// not thread-safe, call it before start;
- (void)enablePerformanceUpload:(BOOL)enablePerformance;

/// start
- (void)startWithType:(JATNetworkOptType)type;
- (void)startWithType:(JATNetworkOptType)type
      concurrentCount:(NSUInteger)concurrentCount;

/// 强制切换到子线程的 path 列表; key: path, value: Number.boolValue 是否需要强制切换
- (void)updateAllowedMatchPathList:(NSDictionary<NSString* , NSNumber *> *)allowedPaths;
/// 这里的 path 是模糊信息, 主要为了解决含有 unique id 的 path,会用 realPath contain:path 去查找是否需要切换线程, 因为涉及到主线程循环遍历所以这里不建议使用下发较多的path. 同时为了性能现在也不支持正则.
- (void)updateAllowedFuzzyPathList:(NSDictionary<NSString* , NSNumber *> *)allowedPaths;


@end

NS_ASSUME_NONNULL_END

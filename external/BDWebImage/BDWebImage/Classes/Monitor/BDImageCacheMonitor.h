//
//  BDImageCacheMonitor.h
//  BDWebImage
//
//  Created by 陈奕 on 2020/2/12.
//

#import <Foundation/Foundation.h>
#import "BDImageCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDImageCacheModle : NSObject

@property (nonatomic, copy) NSString *bizTag;
@property (nonatomic, assign) NSUInteger imageCount;
@property (nonatomic, assign) NSUInteger memoryCount;
@property (nonatomic, assign) NSUInteger diskCount;

- (instancetype)initWithBizTag:(NSString *)bizTag;
- (void)reset;
- (NSMutableDictionary *)dataFromParam;

@end

@interface BDImageCacheMonitor : NSObject

@property (nonatomic, assign) BOOL monitorEnable;

- (void)setTrackInterval:(NSInteger)trackInterval;

- (void)onRecordType:(BDImageCacheType)cacheType bizTag:(NSString *)bizTag;

@end

NS_ASSUME_NONNULL_END

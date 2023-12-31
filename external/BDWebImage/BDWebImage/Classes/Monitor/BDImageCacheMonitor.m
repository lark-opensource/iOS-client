//
//  BDImageCacheMonitor.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/2/12.
//

#import "BDImageCacheMonitor.h"
#import "BDImageMonitorManager.h"

static NSString *const kDefaultBizTag = @"default";
static NSInteger const kDefaultTrackInterval = 60;
static NSInteger const kDefaultMinTracksCount = 200;

@implementation BDImageCacheModle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bizTag = kDefaultBizTag;
    }
    return self;
}

- (instancetype)initWithBizTag:(NSString *)bizTag
{
    self = [super init];
    if (self) {
        self.bizTag = bizTag;
    }
    return self;
}

- (void)reset {
    self.imageCount = 0;
    self.memoryCount = 0;
    self.diskCount = 0;
}

- (NSMutableDictionary *)dataFromParam {
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:@(self.imageCount) forKey:@"image_count"];
    [data setValue:@(self.memoryCount) forKey:@"memory_hit_count"];
    [data setValue:@(self.diskCount) forKey:@"disk_hit_count"];
    return data;
}

@end

@interface BDImageCacheMonitor ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, BDImageCacheModle *> *monitorModels;
@property (nonatomic, strong) dispatch_queue_t monitorQueue;
@property (nonatomic, assign) NSInteger allCount;
@property (nonatomic, assign) NSInteger trackInterval;

@end

@implementation BDImageCacheMonitor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.monitorModels = [NSMutableDictionary dictionary];
        self.monitorQueue = dispatch_queue_create("cache_monitor_queue", DISPATCH_QUEUE_SERIAL);
        self.monitorEnable = NO;
        self.trackInterval = kDefaultTrackInterval;
        [self trackRecursively];
    }
    return self;
}

- (void)setTrackInterval:(NSInteger)trackInterval {
    _trackInterval = trackInterval < kDefaultTrackInterval ? kDefaultTrackInterval : trackInterval;
}

- (void)onRecordType:(BDImageCacheType)cacheType bizTag:(NSString *)bizTag {
    if (!self.monitorEnable) {
        return;
    }
    if (![bizTag isKindOfClass:[NSString class]] || bizTag.length < 1) {
        bizTag = kDefaultBizTag;
    }
    dispatch_async(self.monitorQueue, ^{
        BDImageCacheModle *model = [self.monitorModels objectForKey:bizTag];
        if (!model) {
            model = [[BDImageCacheModle alloc] initWithBizTag:bizTag];
            [self.monitorModels setValue:model forKey:bizTag];
        }
        switch (cacheType) {
            case BDImageCacheTypeMemory:
                model.memoryCount++;
                break;
            case BDImageCacheTypeDisk:
                model.diskCount++;
            default:
                break;
        }
        model.imageCount++;
        self.allCount++;
    });
}

- (void)trackRecursively {
    __weak typeof(self) _self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.trackInterval * NSEC_PER_SEC)), self.monitorQueue, ^{
        __strong typeof(_self) strongSelf = _self;
        if (!strongSelf) {
            return;
        }
        [self trackData];
        [strongSelf trackRecursively];
    });
}

- (void)trackData {
    if (self.allCount < kDefaultMinTracksCount || !self.monitorEnable) {
        return;
    }
    [self.monitorModels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, BDImageCacheModle * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.imageCount > 0) {
            NSDictionary *attributes = [obj dataFromParam];
            double timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
            [BDImageMonitorManager trackService:@"image_cache_hit_monitor" metric:attributes category:@{@"biz_tag": obj.bizTag ?: @""} extra:@{@"timestamp": @((NSInteger)timeStamp)}];
        }
        [obj reset];
    }];
    self.allCount = 0;
}

@end

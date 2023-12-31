//
//  BDImageCacheConfig.m
//  BDWebImage
//
//  Created by lizhuoli on 2017/12/12.
//

#import "BDImageCacheConfig.h"
#import "BDMemoryCache.h"
#import "BDDiskCache.h"

@implementation BDImageCacheConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.clearMemoryOnMemoryWarning = YES;
        self.clearMemoryWhenEnteringBackground = YES;
        self.shouldUseWeakMemoryCache = YES;
        self.memoryCountLimit = NSUIntegerMax;
        self.memorySizeLimit = 256 * 1024 * 1024;
        self.memoryAgeLimit = 12 * 60 * 60;
        self.trimDiskWhenEnteringBackground = YES;
        self.diskCountLimit = NSUIntegerMax;
        self.diskSizeLimit = 256 * 1024 * 1024;
        self.diskAgeLimit = 7 * 24 * 60 * 60;
        self.shouldDisableiCloud = YES;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    BDImageCacheConfig *config = [[self class] allocWithZone:zone];
    config.clearMemoryOnMemoryWarning = self.clearMemoryOnMemoryWarning;
    config.clearMemoryWhenEnteringBackground = self.clearMemoryWhenEnteringBackground;
    config.shouldUseWeakMemoryCache = self.shouldUseWeakMemoryCache;
    config.memoryCountLimit = self.memoryCountLimit;
    config.memorySizeLimit = self.memorySizeLimit;
    config.memoryAgeLimit = self.memoryAgeLimit;
    config.trimDiskWhenEnteringBackground = self.trimDiskWhenEnteringBackground;
    config.diskCountLimit = self.diskCountLimit;
    config.diskSizeLimit = self.diskSizeLimit;
    config.diskAgeLimit = self.diskAgeLimit;
    config.shouldDisableiCloud = self.shouldDisableiCloud;
    return config;
}

@end

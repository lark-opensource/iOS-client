//
//  BDUGAlbumImageCacheManager.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/7/17.
//

static NSInteger const kDefaultImageCacheLength = 5;

static NSString *const kBDUGImageAlbumCacheArrayKey = @"kBDUGImageAlbumCacheArrayKey";
static NSString *const kBDUGImageAlbumCacheDictKey = @"kBDUGImageAlbumCacheDictKey";

#import "BDUGAlbumImageCacheManager.h"

@interface BDUGAlbumImageCacheManager ()

@property (nonatomic, strong) NSMutableArray *cacheArray;
@property (nonatomic, strong) NSMutableDictionary *cacheDict;

@end

@implementation BDUGAlbumImageCacheManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cacheLength = kDefaultImageCacheLength;
    }
    return self;
}

- (void)addCacheWithLocalIdentifier:(NSString *)localIdentifier infoValid:(BOOL)infoValid
{
    if (!localIdentifier || localIdentifier.length == 0) {
        return;
    }
    if ([self.cacheArray containsObject:localIdentifier]) {
        return;
    }
    [self.cacheArray addObject:localIdentifier];
    [self.cacheDict setObject:[NSNumber numberWithBool:infoValid] forKey:localIdentifier];
    
    while (self.cacheArray.count > self.cacheLength) {
        //定长缓存。
        NSString *oldLocalIdentifier = self.cacheArray.firstObject;
        [self.cacheDict removeObjectForKey:oldLocalIdentifier];
        [self.cacheArray removeObjectAtIndex:0];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:self.cacheArray forKey:kBDUGImageAlbumCacheArrayKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.cacheDict forKey:kBDUGImageAlbumCacheDictKey];
}

- (BDUGAlbumImageCacheStatus)cacheStatusWithLocalIdentifier:(NSString *)localIdentifier
{
    if (!localIdentifier || ![self.cacheArray containsObject:localIdentifier]) {
        return BDUGAlbumImageCacheStatusMiss;
    }
    NSNumber *cacheValue = [self.cacheDict objectForKey:localIdentifier];
    if ([cacheValue boolValue]) {
        return BDUGAlbumImageCacheStatusHitValid;
    } else {
        return BDUGAlbumImageCacheStatusHitExit;
    }
}

- (void)cleanCache
{
    [self.cacheArray removeAllObjects];
    [self.cacheDict removeAllObjects];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kBDUGImageAlbumCacheArrayKey];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kBDUGImageAlbumCacheDictKey];
}

- (NSMutableArray *)cacheArray
{
    if (!_cacheArray) {
        // 只需要读取一次
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey:kBDUGImageAlbumCacheArrayKey];
            self->_cacheArray = array.mutableCopy;
        });
        if (!_cacheArray) {
            _cacheArray = [[NSMutableArray alloc] init];
        }
    }
    return _cacheArray;
}

- (NSMutableDictionary *)cacheDict
{
    if (!_cacheDict) {
        // 只需要读取一次
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kBDUGImageAlbumCacheDictKey];
            self->_cacheDict = dict.mutableCopy;
        });
        if (!_cacheDict) {
            _cacheDict = [[NSMutableDictionary alloc] init];
        }
    }
    return _cacheDict;
}

@end

//
//  TSPKSafeMutableDict.m
//  TikTok
//
//  Created by admin on 2021/11/22.
//

#import "TSPKSafeMutableDict.h"

@interface TSPKSafeMutableDict()

@property (nonatomic, strong) NSMutableDictionary *dictionary;
@property (nonatomic, strong) dispatch_queue_t readWriteQuene;

@end

@implementation TSPKSafeMutableDict

- (instancetype)init {
    self = [super init];
    if (self) {
        _dictionary = [NSMutableDictionary dictionary];
        _readWriteQuene = dispatch_queue_create("com.tspk.dict.quene", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)removeObjectForKey:(id)aKey {
    dispatch_barrier_async(self.readWriteQuene, ^{
        [self.dictionary removeObjectForKey:aKey];
    });
}

- (void)setObject:(id)anObject forKey:(id)aKey {
    dispatch_barrier_async(self.readWriteQuene, ^{
        [self.dictionary setObject:anObject forKey:aKey];
    });
}

- (nullable id)objectForKey:(id)aKey {
    __block id item = nil;
    dispatch_sync(self.readWriteQuene, ^{
        item = [self.dictionary objectForKey:aKey];
    });
    return item;
}

- (NSArray *)allKeys {
    __block NSArray *keys;
    dispatch_sync(self.readWriteQuene, ^{
        keys = [self.dictionary allKeys];
    });
    return keys;
}

- (NSArray *)allValues {
    __block NSArray *values;
    dispatch_sync(self.readWriteQuene, ^{
        values = [self.dictionary allValues];
    });
    return values;
}

@end

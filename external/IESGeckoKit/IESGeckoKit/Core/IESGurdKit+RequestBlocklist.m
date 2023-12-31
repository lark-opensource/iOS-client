//
//  IESGurdKit+RequestBlocklist.m
//  Aspects
//
//  Created by 陈煜钏 on 2021/9/13.
//

#import "IESGurdKit+RequestBlocklist.h"

#import "IESGeckoDefines+Private.h"

@interface IESGurdRequestParamsBlocklist : NSObject
- (void)addParams:(NSArray<NSString *> *)params forAccessKey:(NSString *)accessKey;
- (void)removeParams:(NSArray<NSString *> *)params forAccessKey:(NSString *)accessKey;
- (NSArray<NSString *> *)filteredParamsForAccessKey:(NSString *)accessKey originalParams:(NSArray<NSString *> *)originalParams;
- (BOOL)isParamInBlocklistForAccessKey:(NSString *)accessKey param:(NSString *)param;
@end

static IESGurdRequestParamsBlocklist *kGroupNamesBlocklist = nil;
static IESGurdRequestParamsBlocklist *kChannelsBlocklist = nil;

@implementation IESGurdKit (RequestBlocklist)

+ (void)addRequestBlocklistGroupNames:(NSArray<NSString *> *)groupNames forAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || groupNames.count == 0) {
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kGroupNamesBlocklist = [[IESGurdRequestParamsBlocklist alloc] init];
    });
    [kGroupNamesBlocklist addParams:groupNames forAccessKey:accessKey];
}

+ (void)removeRequestBlocklistGroupNames:(NSArray<NSString *> *)groupNames forAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || groupNames.count == 0) {
        return;
    }
    [kGroupNamesBlocklist removeParams:groupNames forAccessKey:accessKey];
}

+ (void)addRequestBlocklistChannels:(NSArray<NSString *> *)channels forAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || channels.count == 0) {
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kChannelsBlocklist = [[IESGurdRequestParamsBlocklist alloc] init];
    });
    [kChannelsBlocklist addParams:channels forAccessKey:accessKey];
}

+ (void)removeRequestBlocklistChannels:(NSArray<NSString *> *)channels forAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || channels.count == 0) {
        return;
    }
    [kChannelsBlocklist removeParams:channels forAccessKey:accessKey];
}

@end

@implementation NSString (IESGurdRequestParams)

- (BOOL)iesgurdkit_shouldRequestGroupNameForForAccessKey:(NSString *)accessKey
{
    if (self.length == 0) {
        return NO;
    }
    if (!kGroupNamesBlocklist) {
        return YES;
    }
    return ![kGroupNamesBlocklist isParamInBlocklistForAccessKey:accessKey param:self];
}

@end

@implementation NSArray (IESGurdRequestParams)

- (NSArray<NSString *> *)iesgurdkit_filteredGroupNamesForAccessKey:(NSString *)accessKey
{
    if (self.count == 0) {
        return self;
    }
    if (!kGroupNamesBlocklist) {
        return self;
    }
    return [kGroupNamesBlocklist filteredParamsForAccessKey:accessKey originalParams:self];
}

- (NSArray<NSString *> *)iesgurdkit_filteredChannelsForAccessKey:(NSString *)accessKey
{
    if (self.count == 0) {
        return self;
    }
    if (!kChannelsBlocklist) {
        return self;
    }
    return [kChannelsBlocklist filteredParamsForAccessKey:accessKey originalParams:self];
}

@end

@implementation IESGurdRequestParamsBlocklist
{
    NSMutableDictionary<NSString *, NSMutableSet *> *blocklistDictionary;
    dispatch_semaphore_t lock;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)addParams:(NSArray<NSString *> *)params forAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || params.count == 0) {
        return;
    }
    
    GURD_SEMEPHORE_LOCK(self->lock);
    
    if (!blocklistDictionary) {
        blocklistDictionary = [NSMutableDictionary dictionary];
    }
    NSMutableSet *set = blocklistDictionary[accessKey];
    if (!set) {
        set = [NSMutableSet set];
        blocklistDictionary[accessKey] = set;
    }
    [set addObjectsFromArray:params];
}

- (void)removeParams:(NSArray<NSString *> *)params forAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || params.count == 0) {
        return;
    }
    if (!blocklistDictionary) {
        return;
    }
    
    GURD_SEMEPHORE_LOCK(self->lock);
    
    NSMutableSet *set = blocklistDictionary[accessKey];
    [params enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL *stop) {
        [set removeObject:param];
    }];
}

- (NSArray<NSString *> *)filteredParamsForAccessKey:(NSString *)accessKey originalParams:(NSArray<NSString *> *)originalParams
{
    if (accessKey.length == 0 || originalParams.count == 0) {
        return originalParams;
    }
    if (!blocklistDictionary) {
        return originalParams;
    }
    
    GURD_SEMEPHORE_LOCK(self->lock);
    
    NSMutableSet *set = blocklistDictionary[accessKey];
    NSMutableArray<NSString *> *paramsInBlocklist = nil;
    for (NSString *param in originalParams) {
        if (![set containsObject:param]) {
            continue;
        }
        if (!paramsInBlocklist) {
            paramsInBlocklist = [NSMutableArray array];
        }
        [paramsInBlocklist addObject:param];
    }
    if (paramsInBlocklist.count == 0) {
        return originalParams;
    }
    NSMutableArray<NSString *> *result = [originalParams mutableCopy];
    [result removeObjectsInArray:paramsInBlocklist];
    return [result copy];
}

- (BOOL)isParamInBlocklistForAccessKey:(NSString *)accessKey param:(NSString *)param
{
    if (accessKey.length == 0 || param.length == 0) {
        return NO;
    }
    if (!blocklistDictionary) {
        return NO;
    }
    
    GURD_SEMEPHORE_LOCK(self->lock);
    
    NSMutableSet *set = blocklistDictionary[accessKey];
    return [set containsObject:param];
}

@end

//
//  IESPrefetchManager.m
//  IESPrefetch
//
//  Created by Hao Wang on 2019/11/15.
//

#import "IESPrefetchManager.h"
#import "IESWebViewSchemaResolver.h"
#import "IESFallbackSchemaResolver.h"
#import "IESPrefetchLogger.h"
#import "IESPrefetchLoader.h"

@interface IESPrefetchManager ()

@property(nonatomic, strong) NSLock *lock;

@property(nonatomic, strong) NSMutableDictionary<NSString *, id<IESPrefetchLoaderProtocol>> *loaderDictionary;
@property(nonatomic, strong) NSMutableArray<id<IESPrefetchSchemaResolver>> *schemaResolvers;

@end

@implementation IESPrefetchManager

+ (IESPrefetchManager *)sharedInstance {
    static dispatch_once_t onceToken;
    static IESPrefetchManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [[NSLock alloc] init];
        _loaderDictionary = [NSMutableDictionary dictionary];
        _schemaResolvers = [NSMutableArray array];
        [self addDefaultSchemaResolver];
    }
    return self;
}

- (id<IESPrefetchLoaderProtocol>)registerCapability:(id<IESPrefetchCapability>)capability forBusiness:(NSString *)business {
    if (business.length == 0) {
        return nil;
    }
    if ([self.loaderDictionary.allKeys containsObject:business]) {
        return nil;
    }
    IESPrefetchLoader *loader = [[IESPrefetchLoader alloc] initWithCapability:capability business:business];
    [self.lock lock];
    [self.schemaResolvers enumerateObjectsUsingBlock:^(id<IESPrefetchSchemaResolver>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [loader registerSchemaResolver:obj];
    }];
    self.loaderDictionary[business] = loader;
    [self.lock unlock];
    return loader;
}

- (id<IESPrefetchLoaderProtocol>)loaderForBusiness:(NSString *)business {
   if (business.length == 0) {
        return nil;
    }
    id<IESPrefetchLoaderProtocol> loader = nil;
    [self.lock lock];
    loader = self.loaderDictionary[business];
    [self.lock unlock];
    return loader;
}

- (void)removeLoaderForBusiness:(NSString *)business
{
    if (business.length == 0) {
        return;
    }
    [self.lock lock];
    self.loaderDictionary[business] = nil;
    [self.lock unlock];
}

- (NSArray<NSString *> *)allBiz
{
    NSArray<NSString *> *results = nil;
    [self.lock lock];
    results = self.loaderDictionary.allKeys;
    [self.lock unlock];
    return results;
}

- (void)registerSchemaResolver:(id<IESPrefetchSchemaResolver>)resolver
{
    if (resolver == nil) {
        return;
    }
    [self.lock lock];
    [self.schemaResolvers addObject:resolver];
    [self.loaderDictionary.allValues enumerateObjectsUsingBlock:^(id<IESPrefetchLoaderProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj registerSchemaResolver:resolver];
    }];
    [self.lock unlock];
}

- (void)prefetchDataWithWebUrl:(NSString *)webUrl {
    [self.lock lock];
    [self.loaderDictionary.allValues enumerateObjectsUsingBlock:^(id<IESPrefetchLoaderProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj prefetchForSchema:webUrl withVariable:nil];
    }];
    [self.lock unlock];
}

#pragma mark - Private

- (void)addDefaultSchemaResolver
{
    [self.lock lock];
    {
        id<IESPrefetchSchemaResolver> resolver = [IESFallbackSchemaResolver new];
        PrefetchSchemaLogD(@"add defaultSchemaResolver: %@", NSStringFromClass([resolver class]));
        [self.schemaResolvers addObject:resolver];
    }
    {
        id<IESPrefetchSchemaResolver> resolver = [IESWebViewSchemaResolver new];
        PrefetchSchemaLogD(@"add defaultSchemaResolver: %@", NSStringFromClass([resolver class]));
        [self.schemaResolvers addObject:resolver];
    }
    [self.lock unlock];
}

@end

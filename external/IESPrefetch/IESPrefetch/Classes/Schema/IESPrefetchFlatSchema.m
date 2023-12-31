//
//  IESPrefetchFlatSchema.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/11/29.
//

#import "IESPrefetchFlatSchema.h"

@interface IESPrefetchFlatSchema ()

@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSString *> *queryItems;
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSString *> *pathVariables;
@property (nonatomic, copy) NSURL *url;

@end

@implementation IESPrefetchFlatSchema

+ (instancetype)schemaWithURL:(NSURL *)url
{
    return [[IESPrefetchFlatSchema alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url
{
    if (url == nil) {
        return nil;
    }
    if (self = [super init]) {
        _url = url;
        _scheme = url.scheme;
        _host = url.host;
        _path = url.path;
        
        [self resolveHashAndQuery:url];
    }
    return self;
}

- (void)resolveHashAndQuery:(NSURL *)url
{
    NSMutableDictionary<NSString *, NSString *> *items = [NSMutableDictionary new];
    [items addEntriesFromDictionary:[self dictFromQueryString:url.query]];
    
    NSArray<NSString *> *fragments = [url.fragment componentsSeparatedByString:@"?"];
    if (fragments.count == 1) {
        self.fragment = fragments.firstObject;
    } else if (fragments.count == 2) {
        self.fragment = fragments.firstObject;
        [items addEntriesFromDictionary:[self dictFromQueryString:fragments.lastObject]];
    }
    
    self.queryItems = [items copy];
}

- (NSDictionary<NSString *, NSString *> *)dictFromQueryString:(NSString *)queryString
{
    NSArray<NSString *> *queries = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary<NSString *, NSString *> *items = [NSMutableDictionary new];
    [queries enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *dictEntry = [obj componentsSeparatedByString:@"="];
        if (dictEntry.count == 2) {
            items[dictEntry[0]] = dictEntry[1];
        }
    }];
    return [items copy];
}

- (NSString *)urlString
{
    return self.url.absoluteString;
}

@end

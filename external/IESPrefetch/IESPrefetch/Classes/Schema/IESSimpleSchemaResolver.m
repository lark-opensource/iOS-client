//
//  IESSimpleSchemaResolver.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/1.
//

#import "IESSimpleSchemaResolver.h"

@interface IESSimpleSchemaResolver ()

@property (nonatomic, copy) NSString *hostname;
@property (nonatomic, copy) NSString *key;

@end

@implementation IESSimpleSchemaResolver

- (instancetype)initWithHost:(NSString *)hostname keyQuery:(NSString *)key
{
    if (self = [super init]) {
        _hostname = hostname;
        _key = key;
    }
    return self;
}

//MARK: - IESPrefetchSchemaResolver

- (BOOL)shouldInterceptHierachicalSchema:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    return [url.host isEqualToString:self.hostname];
}

- (NSURL *)resolveFlatSchema:(NSString *)urlString
{
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    __block NSString *flatUrlString = nil;
    [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:self.key]) {
            flatUrlString = obj.value;
            *stop = YES;
        }
    }];
    if (flatUrlString != nil) {
        return [NSURL URLWithString:flatUrlString];
    }
    return [NSURL URLWithString:urlString];
}

@end

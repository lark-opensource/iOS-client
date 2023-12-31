//
//  IESWebViewSchemaResolver.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/1.
//

#import "IESWebViewSchemaResolver.h"
#import "IESSimpleSchemaResolver.h"

@interface IESWebViewSchemaResolver ()

@property (nonatomic, strong) IESSimpleSchemaResolver *simpleResolver;

@end

@implementation IESWebViewSchemaResolver

- (instancetype)init
{
    if (self = [super init]) {
        _simpleResolver = [[IESSimpleSchemaResolver alloc] initWithHost:@"webview" keyQuery:@"url"];
    }
    return self;
}

//MARK: - IESPrefetchSchemaResolver

- (BOOL)shouldInterceptHierachicalSchema:(NSString *)urlString
{
    return [self.simpleResolver shouldInterceptHierachicalSchema:urlString];
}

- (NSURL *)resolveFlatSchema:(NSString *)urlString
{
    return [self.simpleResolver resolveFlatSchema:urlString];
}

@end

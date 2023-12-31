//
//  BDPAppPageURL.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/29.
//

#import "BDPAppPageURL.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPSchemaCodec+Private.h>

@implementation BDPAppPageURL

- (instancetype _Nullable)initWithURLString:(NSString * _Nullable)url
{
    if (!BDPIsEmptyString(url)) {
        self = [super init];
        if ([self setupContentWithURL:url]) {
            return self;
        }
    }
    return nil;
}

- (BOOL)setupContentWithURL:(NSString *)URL
{
    if (BDPIsEmptyString(URL)) {
        return NO;
    }
    
    __block BOOL result = YES;
    WeakSelf;
    [BDPSchemaCodec separatePathAndQuery:URL syncResultBlock:^(NSString *path, NSString *query, NSDictionary *queryDictionary) {
        StrongSelfIfNilReturn;
        if (BDPIsEmptyString(path)) {
            result = NO;
        }
        self.path = path;
        self.absoluteString = URL;
        self.queryString = query;
    }];
    return result;
}

- (BOOL)isEqualToPage:(BDPAppPageURL * _Nullable)page
{
    if (page && [page isKindOfClass:[BDPAppPageURL class]]) {
        if ([page.path isEqualToString:self.path]) {
            if (BDPIsEmptyString(self.queryString) && BDPIsEmptyString(page.queryString)) {
                return YES;
            } else if ([page.queryString isEqualToString:self.queryString]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else {
        return [self isEqualToPage:other];
    }
}

- (NSUInteger)hash
{
    return self.absoluteString.hash;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"BDPAppPageURL Path: %@ Query: %@", self.path, self.queryString];
}

@end

//
//  NSURL+BulletQuery.m
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/11.
//

#import "NSString+BulletXUrlExt.h"
#import "NSURL+BulletXQueryExt.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <objc/runtime.h>

@implementation NSURL (BulletXQueryExt)

@dynamic bullet_queryParamDict;

- (NSString *)bullet_schemeAndHost
{
    return [NSString stringWithFormat:@"%@://%@", self.scheme, self.host];
}

- (NSDictionary<NSString *, NSString *> *)bullet_queryParamDict
{
    return objc_getAssociatedObject(self, @selector(bullet_queryParamDict));
}

- (void)setBullet_queryParamDict:(NSDictionary<NSString *, NSString *> *)queryParamDict
{
    objc_setAssociatedObject(self, @selector(bullet_queryParamDict), queryParamDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)bullet_findDecodedValueByKey:(NSString *)key
{
    if (!self.bullet_queryParamDict) {
        if (self.query) {
            NSArray<NSString *> *params = [self.query componentsSeparatedByString:@"&"];
            if (params && params.count > 0) {
                NSMutableDictionary<NSString *, NSString *> *mutableDict = [[NSMutableDictionary alloc] init];
                for (NSString *param in params) {
                    if (param) {
                        NSArray<NSString *> *elts = [param componentsSeparatedByString:@"="];
                        if (elts.count >= 2) {
                            mutableDict[elts[0]] = elts[1];
                        }
                    }
                }
                self.bullet_queryParamDict = mutableDict;
            }
        }
    }

    if (self.bullet_queryParamDict && key) {
        NSString *value = self.bullet_queryParamDict[[key bullet_urlEncode]];
        if (value) {
            return [value bullet_urlDecode];
        }
    }

    return nil;
}

- (NSURL *)bullet_urlByAppendingQueryItemWithDictionary:(NSDictionary *)queryItems
{
    if (!queryItems.count) {
        return self;
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:self.absoluteString];
    NSMutableArray *currentItems = [components.queryItems ?: @[] mutableCopy];
    for (NSString *key in queryItems) {
        id value = queryItems[key];
        if (![value isKindOfClass:NSString.class] && [value respondsToSelector:@selector(stringValue)]) {
            value = [value stringValue];
        }
        if ([key isKindOfClass:NSString.class] && [value isKindOfClass:NSString.class]) {
            NSURLQueryItem *newItem = [NSURLQueryItem queryItemWithName:key value:value];
            !newItem ?: [currentItems btd_addObject:newItem];
        }
    }
    [components setQueryItems:currentItems.copy];
    return components.URL;
}

@end

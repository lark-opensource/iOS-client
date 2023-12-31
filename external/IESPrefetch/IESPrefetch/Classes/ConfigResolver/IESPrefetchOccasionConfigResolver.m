//
//  IESPrefetchOccasionConfigResolver.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/3.
//

#import "IESPrefetchOccasionConfigResolver.h"
#import "IESPrefetchOccasionTemplate.h"
#import "IESPrefetchLogger.h"

@implementation IESPrefetchOccasionConfigResolver

- (id<IESPrefetchConfigTemplate>)resolveConfig:(NSDictionary *)config
{
    if (config.count == 0) {
        PrefetchConfigLogD(@"occasion config is empty ");
        return nil;
    }
    NSDictionary *occasionConfig = config[@"occasions"];
    if (!([occasionConfig isKindOfClass:[NSDictionary class]] && occasionConfig.count > 0)) {
        PrefetchConfigLogD(@"occasion config is empty or invalid.");
        return nil;
    }
    IESPrefetchOccasionTemplate *template = [IESPrefetchOccasionTemplate new];
    [occasionConfig enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSArray class]] && obj.count > 0) {
            IESPrefetchOccasionNode *node = [IESPrefetchOccasionNode new];
            node.name = key;
            node.rules = obj;
            [template addOccasionNode:node];
        }
    }];
    if ([template countOfNodes] == 0) {
        return nil;
    }
    return template;
}

@end

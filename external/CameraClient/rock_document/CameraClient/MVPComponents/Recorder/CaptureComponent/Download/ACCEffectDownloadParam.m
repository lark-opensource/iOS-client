//
//  ACCEffectDownloadParam.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/27.
//

#import "ACCEffectDownloadParam.h"

@implementation ACCEffectDownloadParam

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"needUpzip" : @"needUpzip",
        @"urlList" : @"url",
    };
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
    if ([key isEqualToString:@"url"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[NSString class]];
    }
    return nil;
}

@end

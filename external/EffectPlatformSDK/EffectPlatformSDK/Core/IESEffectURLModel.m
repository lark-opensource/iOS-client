//
//  IESEffectURLModel.m
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/9/27.
//

#import "IESEffectURLModel.h"

@implementation IESEffectURLModel

- (NSArray<NSString *> *)URLList
{
    return _originURLList;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"URI" : @"Uri",
        @"originURLList" : @"UrlList"
    };
}


@end

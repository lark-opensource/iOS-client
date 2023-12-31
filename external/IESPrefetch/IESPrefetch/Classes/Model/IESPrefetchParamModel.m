//
//  IESPrefetchParamModel.m
//  IESPrefetch
//
//  Created by Hao Wang on 2019/7/31.
//

#import "IESPrefetchParamModel.h"

@implementation IESPrefetchParamModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _type = [dictionary[@"type"] isEqualToString:@"query"] ? IESPrefetchParamTypeQuery : IESPrefetchParamTypeStatic;
        _value = dictionary[@"value"];
    }
    return self;
}

@end

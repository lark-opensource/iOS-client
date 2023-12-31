//
//  BDModelFacade.m
//  BDModel
//
//  Created by 马钰峰 on 2019/3/28.
//

#import "BDModelFacade.h"
#import "NSObject+BDModel.h"

@implementation BDModel

+ (id)model:(Class)cls withJSON:(id)json
{
    return [self model:cls withJSON:json options:BDModelMappingOptionsNone];
}

+ (id)model:(Class)cls withJSON:(id)json options:(BDModelMappingOptions)options
{
    return [cls bd_modelWithJSON:json options:options];
}

+ (id)model:(Class)cls withDictonary:(NSDictionary *)dictionary
{
    return [cls bd_modelWithDictionary:dictionary];
}

+ (id)toJSONObjectWithModel:(id)model
{
    return [model bd_modelToJSONObject];
}

+ (NSData *)toJSONDataWithModel:(id)model
{
    return [model bd_modelToJSONData];
}

+ (NSString *)toJSONStringWithModel:(id)model
{
    return [model bd_modelToJSONString];
}

@end

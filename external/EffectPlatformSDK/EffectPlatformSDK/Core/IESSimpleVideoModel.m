//
//  IESSimpleVideoModel.m
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/12/10.
//

#import "IESSimpleVideoModel.h"
#import "IESEffectURLModel.h"

@interface IESSimpleVideoModel ()

@property (nonatomic, copy, readwrite) IESEffectURLModel *coverURL;
@property (nonatomic, copy, readwrite) IESEffectURLModel *playURL;
@property (nonatomic, copy, readwrite) NSString *groupID;

@end

@implementation IESSimpleVideoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"coverURL" : @"cover_url_list",
        @"playURL" : @"playaddr_url_list",
        @"groupID" : @"id"
    };
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key
{
    if ([key isEqualToString:@"coverURL"] || [key isEqualToString:@"playURL"]) {
        return [MTLValueTransformer transformerUsingForwardBlock:^id(NSArray *urls, BOOL *success, NSError *__autoreleasing *error) {
            IESEffectURLModel *model = [[IESEffectURLModel alloc] init];
            model.originURLList = urls;
            
            *success = YES;
            
            return model;
        }];
    }
    return nil;
}

@end

//
//  CJPayQueryMergeBindRelationResponse.m
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/9/25.
//

#import "CJPayQueryMergeBindRelationResponse.h"

@implementation CJPayQueryMergeBindRelationResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
                                    @"walletPageUrl" : @"response.wallet_page_url"
                                    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

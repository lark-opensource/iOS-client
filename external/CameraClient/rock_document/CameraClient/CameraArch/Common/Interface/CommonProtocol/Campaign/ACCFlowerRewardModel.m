//
//  ACCFlowerRewardModel.m
//  Indexer
//
//  Created by xiafeiyu on 11/15/21.
//

#import "ACCFlowerRewardModel.h"

@implementation ACCFlowerRewardRequest

- (NSDictionary *)toParams
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    ret[@"enter_from"] = self.enterFrom;
    ret[@"sticker_id"] = self.stickerId;
    ret[@"follow_uid"] = self.followUid;
    return [ret copy];
}

+ (instancetype)requestWithEnterFrom:(NSString *)enterFrom
                         schemaScene:(ACCFLOSceneName)schemaScene
                           stickerId:(NSString *)stickerId
{
    return [self requestWithEnterFrom:enterFrom
                          schemaScene:schemaScene
                            stickerId:stickerId
                            followUid:nil];
}

+ (instancetype)requestWithEnterFrom:(NSString *)enterFrom
                         schemaScene:(ACCFLOSceneName)schemaScene
                           stickerId:(NSString *)stickerId
                           followUid:(NSString *)followUid
{
    NSParameterAssert(enterFrom != nil);
    __kindof ACCFlowerRewardRequest *request = [[self alloc] init];
    request.enterFrom = enterFrom;
    request.stickerId = stickerId;
    request.followUid = followUid;
    request.schemaScene = schemaScene;
    return request;;
}

@end

@implementation ACCFlowerRewardResponse

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return [@{
        @"data" : @"data"
    } acc_apiPropertyKey];
}

@end

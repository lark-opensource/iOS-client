//
//  ACCMusicRecommendPropModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Lincoln on 2020/12/17.
//

#import "ACCMusicRecommendPropModel.h"

@implementation ACCMusicRecommendPropModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"statusCode" : @"status_code",
        @"errorMessage" : @"status_msg",
        @"effectID" : @"effect_id",
    };
}

@end

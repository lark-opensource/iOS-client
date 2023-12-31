//
//  ACCAttributeBuilder+Attribute.m
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import "ACCAttributeBuilder+Attribute.h"

static NSString *const kACCEnterFromKey = @"enter_from";
static NSString *const kACCEnterMethodKey = @"enter_method";
static NSString *const kACCStagingFlagKey = @"_staging_flag";
static NSString *const kACCRequestIDKey = @"request_id";
static NSString *const kACCDurationKey = @"duration";
static NSString *const kACCActionTypeKey = @"action_type";
static NSString *const kACCPreviousPageKey = @"previous_page";
static NSString *const kACCAuthorIDKey = @"author_id";
static NSString *const kACCToUserIDKey = @"to_user_id";
static NSString *const kACCGroupIDKey = @"group_id";
static NSString *const kACCEnterTypeKey = @"enter_type";
static NSString *const kACClogPBKey = @"log_pb";

@implementation ACCAttributeBuilder (Attribute)

- (ACCEventAttribute *)enterFrom
{
    return self.attribute(kACCEnterFromKey);
}

- (ACCEventAttribute *)enterMethod
{
    return self.attribute(kACCEnterMethodKey);
}

- (ACCEventAttribute *)enterType
{
    return self.attribute(kACCEnterTypeKey);
}

- (ACCEventAttribute *)stagingFlag
{
    return self.attribute(kACCStagingFlagKey);
}

- (ACCEventAttribute *)requestID
{
    return self.attribute(kACCRequestIDKey);
}

- (ACCEventAttribute *)duration
{
    return self.attribute(kACCDurationKey);
}

- (ACCEventAttribute *)actionType
{
    return self.attribute(kACCActionTypeKey);
}

- (ACCEventAttribute *)previousPage
{
    return self.attribute(kACCPreviousPageKey);
}

- (ACCEventAttribute *)authorID
{
    return self.attribute(kACCAuthorIDKey);
}

- (ACCEventAttribute *)toUserID
{
    return self.attribute(kACCToUserIDKey);
}

- (ACCEventAttribute *)groupID
{
    return self.attribute(kACCGroupIDKey);
}

- (ACCEventAttribute *)logPB
{
    return self.attribute(kACClogPBKey);
}

@end

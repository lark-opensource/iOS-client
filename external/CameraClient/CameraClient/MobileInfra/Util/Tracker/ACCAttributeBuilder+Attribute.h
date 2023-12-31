//
//  ACCAttributeBuilder+Attribute.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import "ACCAttributeBuilder.h"

@interface ACCAttributeBuilder (Attribute)
- (ACCEventAttribute *)enterFrom;
- (ACCEventAttribute *)enterMethod;
- (ACCEventAttribute *)enterType;
- (ACCEventAttribute *)stagingFlag;
- (ACCEventAttribute *)requestID;
- (ACCEventAttribute *)duration;
- (ACCEventAttribute *)actionType;
- (ACCEventAttribute *)previousPage;
- (ACCEventAttribute *)authorID;
- (ACCEventAttribute *)toUserID;
- (ACCEventAttribute *)groupID;
- (ACCEventAttribute *)logPB;
@end

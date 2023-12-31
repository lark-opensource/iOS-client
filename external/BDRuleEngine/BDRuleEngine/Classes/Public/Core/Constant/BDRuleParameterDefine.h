//
//  BDRuleParameterDefine.h
//  Pods
//
//  Created by WangKun on 2021/12/9.
//

#ifndef BDRuleParameterDefine_h
#define BDRuleParameterDefine_h

typedef NS_ENUM(NSUInteger, BDRuleParameterType) {
    BDRuleParameterTypeNumberOrBool = 1,
    BDRuleParameterTypeString = 2,
    BDRuleParameterTypeArray = 3,
    BDRuleParameterTypeDictionary = 4,
    BDRuleParameterTypeUnknown = 999
};

typedef NS_ENUM(NSUInteger, BDRuleParameterOrigin) {
    BDRuleParameterOriginState = 1,
    BDRuleParameterOriginConst = 2
};

@protocol BDRuleParameterBuilderProtocol;
typedef id _Nonnull (^BDRuleParameterBuildBlock)(id<BDRuleParameterBuilderProtocol> _Nullable fetcher);

#endif /* BDRuleParameterDefine_h */

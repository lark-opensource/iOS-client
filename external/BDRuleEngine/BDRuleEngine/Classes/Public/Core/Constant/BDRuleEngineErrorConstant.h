//
//  BDRuleEngineErrorHandler.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/29.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSErrorDomain const BDRuleParameterErrorDomain;

typedef NS_ENUM(NSInteger, BDRuleParameterErrorCode)
{
    BDRuleParameterErrorKeyNotRegistered = -1,
    BDRuleParameterErrorKeyRegisterTypeNotMatch = -2,
    BDRuleParameterErrorKeyBuilderTypeNotMatch = -3,
    BDRuleParameterErrorKeyBuilderParameterMiss = -4,
};

FOUNDATION_EXPORT NSErrorDomain const BDStrategyCenterErrorDomain;

typedef NS_ENUM(NSInteger, BDStrategyCenterErrorCode)
{
    BDStrategyCenterErrorCodeSetMapNotFound = -100,
    BDStrategyCenterErrorCodeNoSetNameInResult = -101,
    BDStrategyCenterErrorCodeStrategyMapNotFound = -102,
    BDStrategyCenterErrorCodeNoRuleSetInResult = -103,
    BDStrategyCenterErrorCodeErrorRuleSetTypeInResult = -104,
    BDStrategyCenterErrorCodeRuleSetNotFound = -105,
};

FOUNDATION_EXPORT NSErrorDomain const BDQuickExecutorErrorDomain;

typedef NS_ENUM(NSInteger, BDQuickExecutorErrorCode)
{
    BDQuickExecutorErrorCodeConstTypeNotBool = -200,
};


//
//  IWKPluginHandleResultObj.h
//  BDWebCore
//
//  Created by li keliang on 2019/6/30.
//

#import <Foundation/Foundation.h>
@class IWKPluginHandleResultObj;

NS_ASSUME_NONNULL_BEGIN

typedef IWKPluginHandleResultObj * IWKPluginHandleResultType;

typedef NS_ENUM(NSUInteger, IWKPluginHandleResultFlow) {
    IWKPluginHandleResultFlowContinue   = 0,
    IWKPluginHandleResultFlowBreak      = 1
};

@interface IWKPluginHandleResultObj<ObjectType> : NSObject

@property (nonatomic, readwrite) IWKPluginHandleResultFlow flow;

@property (nonatomic, readwrite, nullable) ObjectType value;

+ (IWKPluginHandleResultObj *)continue;

+ (IWKPluginHandleResultObj *)break;

+ (IWKPluginHandleResultObj *)returnYES;

+ (IWKPluginHandleResultObj *)returnNO;

+ (IWKPluginHandleResultObj<ObjectType> *)returnValue:(ObjectType)value;

@end

#define IWKPluginHandleResultContinue ([IWKPluginHandleResultObj continue])

#define IWKPluginHandleResultBreak ([IWKPluginHandleResultObj break])

#define IWKPluginHandleResultReturnYES ([IWKPluginHandleResultObj returnYES])

#define IWKPluginHandleResultReturnNO ([IWKPluginHandleResultObj returnNO])

#define IWKPluginHandleResultWrapValue(value) ([IWKPluginHandleResultObj returnValue:value])

NS_ASSUME_NONNULL_END

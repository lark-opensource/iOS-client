//
//  IWKPluginHandleResultObj.m
//  BDWebCore
//
//  Created by li keliang on 2019/6/30.
//

#import "IWKPluginHandleResultObj.h"

@implementation IWKPluginHandleResultObj

+ (IWKPluginHandleResultObj *)continue
{
    IWKPluginHandleResultObj *obj = [IWKPluginHandleResultObj new];
    obj.flow = IWKPluginHandleResultFlowContinue;
    return obj;
}

+ (IWKPluginHandleResultObj *)break
{
    IWKPluginHandleResultObj *obj = [IWKPluginHandleResultObj new];
    obj.flow = IWKPluginHandleResultFlowBreak;
    return obj;
}

+ (IWKPluginHandleResultObj *)returnYES
{
    IWKPluginHandleResultObj *obj = [IWKPluginHandleResultObj new];
    obj.value = (__bridge id _Nullable)((void *)YES);
    obj.flow = IWKPluginHandleResultFlowBreak;
    return obj;
}

+ (IWKPluginHandleResultObj *)returnNO
{
    IWKPluginHandleResultObj *obj = [IWKPluginHandleResultObj new];
    obj.value = (__bridge id _Nullable)((void *)NO);
    obj.flow = IWKPluginHandleResultFlowBreak;
    return obj;
}

+ (IWKPluginHandleResultObj *)returnValue:(id)value
{
    IWKPluginHandleResultObj *obj = [IWKPluginHandleResultObj new];
    obj.value = value;
    obj.flow = IWKPluginHandleResultFlowBreak;
    return obj;
}

@end

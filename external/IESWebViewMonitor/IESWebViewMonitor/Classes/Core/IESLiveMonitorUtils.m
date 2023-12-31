//
//  IESLiveMonitorUtils.m
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/7/16.
//

#import "IESLiveMonitorUtils.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "BDMonitorThreadManager.h"
#import "BDHybridMonitorDefines.h"

#ifdef IESWebViewMonitor_POD_VERSION
static NSString *const kIESWebViewMonitorPodVersion = IESWebViewMonitor_POD_VERSION;
#else
static NSString *const kIESWebViewMonitorPodVersion = @"1.3.4";
#endif

static void addMethodToClass(Class cls, NSString *selStr, IMP *ORIGMethodRef, IMP hookMethodRef, const char *description) {
    SEL sel = NSSelectorFromString(selStr);
    Method method = class_getInstanceMethod(cls, sel);
    if (method) {
        const char *type = method_getTypeEncoding(method);
        IMP ORIGImp = method_getImplementation(method);
        if (ORIGImp != hookMethodRef) {
            *ORIGMethodRef = ORIGImp;
            class_replaceMethod(cls, sel, hookMethodRef, type);
        }
    } else {
        class_addMethod(cls, sel, hookMethodRef, description);
    }
}

static NSDictionary *mergedSettingWithOnlineSetting(NSDictionary *onlineSetting) {
    static dispatch_once_t onceToken;
    static NSDictionary *defaultSetting = nil;
    dispatch_once(&onceToken, ^{
        defaultSetting = @{@"reportResourceThreshold": @(15000),
                           @"reportBlockList":@[@"about:blank"],
                           };
    });
    if (!onlineSetting || ![onlineSetting isKindOfClass:[NSDictionary class]]) {
        return defaultSetting;
    }
    NSMutableDictionary *result = [defaultSetting mutableCopy];
    [onlineSetting enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        result[key] = obj;
    }];
    // 黑名单要做merge操作
    if (onlineSetting[@"reportBlockList"]) {
        NSMutableArray *origList = [onlineSetting[@"reportBlockList"] mutableCopy];
        [origList addObjectsFromArray:defaultSetting[@"reportBlockList"]];
        result[@"reportBlockList"] = [origList copy];
    }
    return [result copy];
}

static IMP hookMethodWithIMP(Class cls, SEL sel, IMP imp) {
    Method method = class_getInstanceMethod(cls, sel);
    IMP ORIGImp = nil;
    if (method && imp) {
        const char *type = method_getTypeEncoding(method);
        ORIGImp = method_getImplementation(method);
        if (ORIGImp && ORIGImp != imp) {
            ORIGImp = class_replaceMethod(cls, sel, imp, type);
        }
        
        if (!ORIGImp) {
            ORIGImp = method_getImplementation(method);
        }
    }
    return ORIGImp != imp ? ORIGImp : nil;
}

static void unHookMethodWithIMP(Class cls, SEL sel, IMP ORIGImp) {
    if (ORIGImp) {
        Method method = class_getInstanceMethod(cls, sel);
        method_setImplementation(method, ORIGImp);
    }
}

static NSString *convertToJsonData(NSDictionary *dict, BOOL needTrim) {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = @"";
    
    if (!jsonData) {
#if DEBUG
        NSLog(@"%@",error);
#endif
        return @"";
    } else {
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    if (needTrim) {
        NSRange range = {0,jsonString.length};
        
        //去掉字符串中的空格
        [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
        
        NSRange range2 = {0,mutStr.length};
        
        //去掉字符串中的换行符
        [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    }
    
    return [mutStr copy];
}

@implementation IESLiveMonitorUtils

+ (IMP)hookMethod:(Class)cls
              sel:(SEL)sel
              imp:(IMP)imp {
    return hookMethodWithIMP(cls, sel, imp);
}

+ (void)unHookMethod:(Class)cls
                 sel:(SEL)sel
                 imp:(IMP)imp {
    unHookMethodWithIMP(cls, sel, imp);
}

+ (void)addMethodToClass:(Class)cls
                  selStr:(NSString*)selStr
                 funcPtr:(IMP*)ORIGMethodRef
              hookMethod:(IMP)hookMethodRef
                    desp:(const char*)description {
    addMethodToClass(cls, selStr, ORIGMethodRef, hookMethodRef, description);
}

+ (NSDictionary *)mergedSettingWithOnlineSetting:(NSDictionary*)onlineSetting {
    return mergedSettingWithOnlineSetting(onlineSetting);
}

+ (NSString *)convertToJsonData:(NSDictionary*)dict {
    return convertToJsonData(dict,NO);
}

+ (NSString *)convertAndTrimToJsonData:(NSDictionary*)dict {
    return convertToJsonData(dict,YES);
}

+ (IMP)getORIGImp:(NSDictionary *)dic cls:(Class)cls ORIGCls:(Class*)ORIGCls sel:(NSString *)selStr {
    return [self getORIGImp:dic cls:cls ORIGCls:ORIGCls sel:selStr assert:YES];
}
    
+ (IMP)getORIGImp:(NSDictionary *)dic
              cls:(Class)cls
          ORIGCls:(Class _Nullable * _Nullable)ORIGCls
              sel:(NSString *)selStr
           assert:(BOOL)assert {
    while (cls) {
        NSDictionary *clsDic = dic[cls];
        if ([clsDic isKindOfClass:[NSDictionary class]]) {
            NSValue *pValue = clsDic[selStr];
            if (pValue) {
                if (ORIGCls) {
                    *ORIGCls = cls;
                }
                return [pValue pointerValue];
            }
        }
        cls = [cls superclass];
    }
#if DEBUG
    if (assert) {
        NSString *className = NSStringFromClass(cls);
        NSAssert(NO, @"No original method，class:%@，sel:%@",className?:@"",selStr?:@"");
    }
#endif
    return nil;
}

+ (BOOL)hookMethod:(Class)cls
        fromSelStr:(NSString*)fromSelStr
          toSelStr:(NSString*)toSelStr
         targetIMP:(IMP)targetIMP {
    Method fromMethod = class_getInstanceMethod(cls, NSSelectorFromString(fromSelStr));
    Method toMethod = class_getInstanceMethod(cls, NSSelectorFromString(toSelStr));
    if (fromMethod
        && toMethod) {
        IMP fromImp = method_getImplementation(fromMethod);
        const char *types = method_getTypeEncoding(fromMethod);
        if (fromImp != targetIMP) {
            SEL ORIGSel = NSSelectorFromString([NSString stringWithFormat:@"%@%@", kBDWMORIGPrefix, fromSelStr]);
            BOOL addORIGMethod = class_addMethod(cls,
                                                 ORIGSel,
                                                 fromImp,
                                                 types);
            class_replaceMethod(cls, NSSelectorFromString(fromSelStr), targetIMP, types);
            class_replaceMethod(cls, NSSelectorFromString(toSelStr), fromImp, types);
            return addORIGMethod;
        } else {
            return class_addMethod(cls,
                                       NSSelectorFromString([NSString stringWithFormat:@"%@%@", kBDWMORIGPrefix, fromSelStr]),
                                       method_getImplementation(toMethod),
                                       types);
        }
        return YES;
    }
    return NO;
};

+ (long long)formatedTimeInterval {
    return (long long)([[NSDate date] timeIntervalSince1970] * 1000);
}

+ (BOOL)isSpecifiedClass:(Class)class confirmsToSel:(SEL)sel {
    IMP classMethod = class_getMethodImplementation(class, sel);
    if (!classMethod || classMethod == _objc_msgForward) {
        return NO;
    } else if ([class isEqual:NSObject.class]) {
        return YES;
    }
    IMP superClassMethod = class_getMethodImplementation([class superclass],sel);
    return classMethod != superClassMethod;
}

+ (NSString *)pageNameForAttachView:(UIView *)view {
    if (!view || ![view isKindOfClass:UIView.class]) {
        return nil;
    }
    __block NSString *pageName = nil;
    [BDMonitorThreadManager dispatchSyncHandlerForceOnMainThread:^{
        UIResponder *nextResponder = view.nextResponder;
        while (nextResponder && ![nextResponder isKindOfClass:UIViewController.class]) {
            nextResponder = nextResponder.nextResponder;
        }
        if ([nextResponder isKindOfClass:UIViewController.class]) {
            pageName = NSStringFromClass(nextResponder.class);
        }
    }];
    return pageName;
}

+ (NSString *)iesWebViewMonitorVersion {
    if ([kIESWebViewMonitorPodVersion isKindOfClass:[NSString class]]) {
        return kIESWebViewMonitorPodVersion;
    }
    return @"1.3.4_unknown";
}

@end

@implementation NSObject (IESLiveCallORIG)

- (Class)lastCallClass {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setLastCallClass:(Class)lastCallClass {
    objc_setAssociatedObject(self, @selector(lastCallClass), lastCallClass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)lastParamsId {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setLastParamsId:(NSString *)lastParamsId {
    objc_setAssociatedObject(self, @selector(lastParamsId), lastParamsId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSMutableDictionary *)lastCallClassForSelDic {
    NSDictionary *dic = (NSDictionary *)objc_getAssociatedObject(self, _cmd);
    return [dic mutableCopy];
}

- (void)setLastCallClassForSelDic:(NSMutableDictionary *)lastCallClassForSelDic {
    objc_setAssociatedObject(self, @selector(lastCallClassForSelDic), lastCallClassForSelDic, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)modifyLastCallClass:(Class)lastCallClass forSelName:(NSString *)selName {
    NSMutableDictionary *dic = [self lastCallClassForSelDic];
    if (!dic) {
        dic = [[NSMutableDictionary alloc] init];
    }
    if (!lastCallClass) {
        [dic removeObjectForKey:selName];
    } else {
        [dic setObject:lastCallClass forKey:selName];
    }
    [self setLastCallClassForSelDic:dic];
}

- (Class)fetchLastCallClassForSelName:(NSString *)selName {
    NSDictionary *dic = [self lastCallClassForSelDic];
    if (!dic || selName.length<=0) {
        return nil;
    }
    Class cls = [dic objectForKey:selName];
    return cls;
}

@end

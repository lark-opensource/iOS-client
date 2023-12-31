//
//  IESLiveMonitorUtils.h
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/7/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define IESWebViewPrepareCallORIG \
[slf setLastCallClass:[methodCls superclass]];

#define IESWebViewSafeCallORIG(slf, code) \
Class lastCallClass = [slf lastCallClass]; \
Class methodCls = [slf class]; \
Class curCls = [slf lastCallClass] ?: [slf class]; \
code \
curCls = nil; \
methodCls = nil; \
[slf setLastCallClass:lastCallClass];


@interface IESLiveMonitorUtils : NSObject

+ (IMP)hookMethod:(Class)cls
              sel:(SEL)sel
              imp:(IMP)imp;

+ (BOOL)hookMethod:(Class)cls
        fromSelStr:(NSString*)fromSelStr
          toSelStr:(NSString*)toSelStr
         targetIMP:(IMP)targetIMP;

+ (void)unHookMethod:(Class)cls
                 sel:(SEL)sel
                 imp:(IMP)imp;

+ (void)addMethodToClass:(Class)cls
                  selStr:(NSString*)selStr
                 funcPtr:(IMP _Nullable*_Nullable)ORIGMethodRef
              hookMethod:(IMP)hookMethodRef
                    desp:(const char*)description;

+ (NSDictionary *)mergedSettingWithOnlineSetting:(NSDictionary*)onlineSetting;

+ (NSString *)convertToJsonData:(NSDictionary*)dict;
+ (NSString *)convertAndTrimToJsonData:(NSDictionary*)dict;

+ (IMP)getORIGImp:(NSDictionary *)dic
              cls:(Class)cls
          ORIGCls:(Class _Nullable * _Nullable)ORIGCls
              sel:(NSString *)selStr;

+ (IMP)getORIGImp:(NSDictionary *)dic
              cls:(Class)cls
          ORIGCls:(Class _Nullable * _Nullable)ORIGCls
              sel:(NSString *)selStr
           assert:(BOOL)assert;

+ (long long)formatedTimeInterval;

// 该类是否实现某方法，不包括父类的实现
+ (BOOL)isSpecifiedClass:(Class)class confirmsToSel:(SEL)sel;

+ (NSString *)pageNameForAttachView:(UIView *)view;

+ (NSString *)iesWebViewMonitorVersion;

@end

@interface NSObject (IESLiveCallORIG)

@property (nonatomic, strong, nullable) Class lastCallClass;
@property (nonatomic, copy, nullable) NSString *lastParamsId;

- (void)modifyLastCallClass:(nullable Class)lastCallClass forSelName:(NSString *)selName;
- (Class)fetchLastCallClassForSelName:(NSString *)selName;

@end

NS_ASSUME_NONNULL_END

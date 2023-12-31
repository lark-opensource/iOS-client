//
//  BDNativeWebComponentLogic.m
//  ByteWebView
//
//  Created by liuyunxuan on 2019/6/12.
//

#import "BDNativeWebComponentLogic.h"
#import "NSDictionary+BDNativeWebHelper.h"
#import "NSString+BDNativeWebHelper.h"
#import "NSArray+BDNativeWebHelper.h"
#import "BDNativeWebContainerObject.h"
#import "BDNativeWebContainerView.h"
#import "BDNativeWebBaseComponent.h"
#import "BDNativeWebBaseComponent+Private.h"
#import "BDNativeWebLogManager.h"
#import <objc/runtime.h>

@interface BDNativeWebComponentLogic()

@property (nonatomic, readonly, class) NSMutableDictionary *nativeComponentClassDic;
@property (nonatomic, strong) NSMutableDictionary *nativeComponentDic;

@end

@implementation BDNativeWebComponentLogic

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.nativeComponentDic = [self.class.nativeComponentClassDic mutableCopy];
    }
    return self;
}

- (void)handleInvokeFunction:(NSDictionary *)params completion:(nonnull void (^)(BOOL, NSDictionary * _Nullable))completion {
    NSString *functionName = [params bdNative_stringValueForKey:@"func"];
    if ([functionName isEqualToString:@"initialize"]) {
        [self invokeInitialize:params completion:completion];
    } else if ([functionName isEqualToString:@"update"]) {
        [self invokeupdate:params completion:completion];
    } else if ([functionName isEqualToString:@"destroy"]) {
        [self invokeDestory:params completion:completion];
    }
}

- (void)handleCallbackFunction:(NSDictionary *)params completion:(nonnull void (^)(BOOL, NSDictionary * _Nullable))completion {
}

- (void)invokeInitialize:(NSDictionary *)params completion:(nonnull void (^)(BOOL, NSDictionary * _Nullable))completion {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *tagID = [params bdNative_stringValueForKey:@"id"];
    NSString *paramsString = [params bdNative_stringValueForKey:@"params"];
    NSDictionary *paramsDic = [paramsString bdNativeJSONDictionary];
    if (tagID.length > 0) {
        // iFrameID 传到 data 里面用
        [dict addEntriesFromDictionary:@{@"id":tagID}];
    }
    if (paramsDic.count) {
        [dict addEntriesFromDictionary:paramsDic];
        [self insertNativeTag:dict completion:completion];
    }
}

- (void)invokeupdate:(NSDictionary *)params completion:(nonnull void (^)(BOOL, NSDictionary * _Nullable))completion {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *tagID = [params bdNative_stringValueForKey:@"id"];
    NSString *paramsString = [params bdNative_stringValueForKey:@"params"];
    NSDictionary *paramsDic = [paramsString bdNativeJSONDictionary];
    if (tagID.length > 0) {
        // iFrameID 传到 data 里面用
        [dict addEntriesFromDictionary:@{@"id":tagID}];
    }
    if (paramsDic.count) {
        [dict addEntriesFromDictionary:paramsDic];
        [self updateNativeTag:dict];
    }
}

- (void)invokeDestory:(NSDictionary *)params completion:(nonnull void (^)(BOOL, NSDictionary * _Nullable))completion {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *tagID = [params bdNative_stringValueForKey:@"id"];
    NSString *paramsString = [params bdNative_stringValueForKey:@"params"];
    NSDictionary *paramsDic = [paramsString bdNativeJSONDictionary];
    if (tagID.length > 0) {
        // iFrameID 传到 data 里面用
        [dict addEntriesFromDictionary:@{@"id":tagID}];
    }
    if (paramsDic.count) {
        [dict addEntriesFromDictionary:paramsDic];
    }
    [self deleteNativeTag:dict];
}

- (void)insertNativeTag:(NSDictionary *)param completion:(nonnull void (^)(BOOL, NSDictionary * _Nullable))completion
{
    if (![param bdNative_objectForKey:@"id"])
    {
        if (completion) {
            completion(NO,nil);
        }
        return;
    }
    
    NSInteger tagId = [param bdNative_intValueForKey:@"id"];
    NSInteger index = [param bdNative_intValueForKey:@"id"];
    NSInteger scrollContentWidth = [param bdNative_intValueForKey:@"scrollContentWidth"];
    NSString *type = [param bdNative_stringValueForKey:@"type"];
    NSDictionary *dataParam = [param bdNative_objectForKey:@"properties"];
    NSString *iFrameID = [param bdNative_stringValueForKey:@"iFrameID"];

    __weak typeof(self) weakSelf = self;
    [self.delegate bdNative_attachWebScrollViewByIndex:index
                                              tryCount:20
                                    scrollContentWidth:scrollContentWidth
                                            completion:^(UIScrollView * _Nonnull scrollView, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (scrollView == nil) {
            if (completion) {
                completion(NO,nil);
            }
            return;
        }
        
        Class nativeClass = [self.nativeComponentDic objectForKey:type];
        if (nativeClass == nil) {
            if (completion) {
                completion(NO,nil);
            }
            return;
        }
        
        BDNativeWebContainerObject *object = [[BDNativeWebContainerObject alloc] init];
        BDNativeWebContainerView *containerView = [[BDNativeWebContainerView alloc] init];
        
        object.scrollView = scrollView;
        object.containerView = containerView;
        object.containerView.frame = scrollView.bounds;
        [object.scrollView addSubview:containerView];
        
        BDNativeWebBaseComponent *component = (BDNativeWebBaseComponent *)[[nativeClass alloc] init];
        component.tagId = @(tagId);
        component.iFrameID = iFrameID;
        component.webView = self.delegate.bdNative_nativeComponentWebView;
        
        object.component = component;
        UIView *natieView = [object.component insertInNativeContainerObject:object params:dataParam];
        natieView.frame = object.containerView.frame;
        [object.containerView addSubview:natieView];
        
        object.nativeView = natieView;
        [object enableObserverFrameChanged];
        [object.component baseInsertInNativeContainerObject:object params:dataParam];
        [self.containerObjects setObject:object forKey:@(tagId)];
        if (completion) {
            completion(YES,nil);
        }
    }];
}

- (NSArray *)checkNativeInfos
{
    NSMutableArray *resultDataArray = [NSMutableArray array];
    for (BDNativeWebContainerObject *object in self.containerObjects.allValues)
    {
        NSMutableDictionary *info = [object checkNativeInfo];
        if (info) {
            [resultDataArray addObject:info];
        }
    }
    
    return resultDataArray;
}

- (void)clearNativeComponentWithIFrameID:(NSString *)iFrameID {
    if (iFrameID == nil) {
        [self clearNativeComponent];
        return ;
    }
    NSMutableArray *removeKeys = [NSMutableArray array];
    [self.containerObjects enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, BDNativeWebContainerObject * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.component.iFrameID isEqualToString:iFrameID]) {
            [removeKeys addObject:key];
        }
    }];
    [self.containerObjects removeObjectsForKeys:removeKeys];
}

- (void)clearNativeComponent
{
    BDNativeInfo(@"clearNativeComponent");
    [self.containerObjects removeAllObjects];
}

- (NSArray *)updateNativeTags:(NSArray *)params
{
    NSMutableArray *resultDics = [NSMutableArray array];
    
    for (NSDictionary *param in params)
    {
        BOOL result = [self updateNativeTag:param];
        
        NSMutableDictionary *resultDic = [param mutableCopy];
        if (result) {
            [resultDic setObject:@(0) forKey:@"result"];
        }else{
            [resultDic setObject:@(-1) forKey:@"result"];
        }
        
        [resultDic removeObjectForKey:@"data"];
        [resultDics addObject:resultDic];
    }
    return resultDics;
}

- (NSArray *)deleteNativeTags:(NSArray *)params
{
    NSMutableArray *resultDics = [NSMutableArray array];
    for (NSDictionary *param in params)
    {
        [self deleteNativeTag:param];
    }
    
    return resultDics;
}

- (BOOL)updateNativeTag:(NSDictionary *)param
{
    NSInteger tagId = [param bdNative_intValueForKey:@"id"];
    BDNativeWebContainerObject *containerObject = [self.containerObjects objectForKey:@(tagId)];
    
    if (containerObject == nil) {
        return NO;
    }
    NSDictionary *dataParam = [param bdNative_dictionaryValueForKey:@"properties"];
    [containerObject.component updateInNativeContainerObject:containerObject params:dataParam];
    [containerObject.component baseUpdateInNativeContainerObject:containerObject params:dataParam];
    return YES;
}

- (void)deleteNativeTag:(NSDictionary *)param
{
    NSInteger index = [param bdNative_intValueForKey:@"id"];
    NSDictionary *dataParam = [param bdNative_objectForKey:@"data"];
    
    BDNativeWebContainerObject *containerObject = [self.containerObjects objectForKey:@(index)];
    if (containerObject.component) {
        [containerObject.component deleteInNativeContainerObject:containerObject params:dataParam];
        [containerObject.component baseDeleteInNativeContainerObject:containerObject params:dataParam];
    }
    [self.containerObjects removeObjectForKey:@(index)];
}

- (void)dispatchAction:(NSDictionary *)param callback:(BDNativeDispatchActionCallback)callback
{
    NSInteger index = [param bdNative_intValueForKey:@"id"];
    NSString *method = [param bdNative_stringValueForKey:@"methodName"];
    NSDictionary *dataParam = [param bdNative_dictionaryValueForKey:@"data"];

    BDNativeWebContainerObject *containerObject = [self.containerObjects objectForKey:@(index)];
    NSDictionary *responseData = nil;
    if (containerObject.component) {
        [containerObject.component actionInNativeContainerObject:containerObject
                                                          method:method
                                                          params:param
                                                        callback:callback];
        
    }else{
        callback(@{
            @"msg":@"can not find component"
        });
    }
}

#pragma mark - initlize getter
- (NSMutableDictionary *)containerObjects
{
    if (!_containerObjects) {
        _containerObjects = [NSMutableDictionary dictionary];
    }
    return _containerObjects;
}

+ (void)registerGloablNativeComponent:(NSArray<Class> *)components
{
    for (Class class in components)
    {
        if ([class isSubclassOfClass:[BDNativeWebBaseComponent class]])
        {
            [self.nativeComponentClassDic setValue:class forKey:[class nativeTagName]];
        }
        else
        {
            NSAssert(NO, @"class is not subclass of BDNativeWebBaseComponent");
        }
    }
}

- (void)registerNativeComponent:(NSArray<Class> *)components
{
    NSMutableDictionary *supportListDic = [NSMutableDictionary dictionary];
    for (Class class in components)
    {
        if ([class isSubclassOfClass:[BDNativeWebBaseComponent class]])
        {
            [self.nativeComponentDic setValue:class forKey:[class nativeTagName]];
            [supportListDic setValue:[class nativeTagVersion] forKey:[class nativeTagName]];
        }
        else
        {
            NSAssert(NO, @"class is not subclass of BDNativeWebBaseComponent");
        }
    }
    NSDictionary *configDic = @{
        @"mixrender_component_support_list": supportListDic
    };
    NSString *script = [NSString stringWithFormat:@"!function(){window.byted_mixrender_config=%@}();",[configDic bdNative_JSONRepresentation]];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self.delegate.bdNative_nativeComponentWebView.configuration.userContentController addUserScript:userScript];
}

static NSMutableDictionary *nativeComponentClassDic = nil;
+ (NSMutableDictionary *)nativeComponentClassDic
{
    if (nativeComponentClassDic == nil) {
        nativeComponentClassDic = [NSMutableDictionary dictionary];
    }
    return nativeComponentClassDic;
}

- (NSMutableDictionary *)nativeComponentDic
{
    if (_nativeComponentDic == nil)
    {
        _nativeComponentDic = [NSMutableDictionary dictionary];
    }
    return _nativeComponentDic;
}

@end

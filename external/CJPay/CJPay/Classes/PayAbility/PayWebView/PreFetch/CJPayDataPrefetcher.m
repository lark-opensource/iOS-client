//
//  CJPayDataPrefetcher.m
//  CJPay
//
//  Created by wangxinhua on 2020/5/13.
//

#import "CJPayDataPrefetcher.h"
#import "CJPayBaseRequest.h"
#import "CJPaySDKMacro.h"

@interface CJPayDataPrefetcher()

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSDictionary *requestParams;
@property (nonatomic, copy) NSString *requestUrl;
@property (nonatomic, strong) CJPayPrefetchRequestModel *curModel;
@property (nonatomic, strong) CJPayPrefetchConfig *config;
// 请求返回的信息
@property (nonatomic, strong) id data;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) NSMutableArray<void(^)(id data, NSError *error)> *dataCallbacks;
@property (nonatomic, assign, readwrite) BOOL dataReady;

@end

@implementation CJPayDataPrefetcher
- (instancetype)initWith:(NSString *)requestUrl prefetchConfig:(CJPayPrefetchConfig *)config {
    self = [super init];
    if (self) {
        _requestUrl = requestUrl;
        _config = config;
        _dataReady = NO;
    }
    return self;
}

// 会耗时，异步调用
- (void)p_processRequestData:(CJPayPrefetchConfig *)config {
    
    // 防止重复解析
    if (self.requestParams) {
        return;
    }
    
    CJPayPrefetchRequestModel *model = [config getRequestModelByUrl:self.requestUrl];
    if (!model) {
        return;
    }
    self.curModel = model;
    
    // 1. 处理请求参数
    NSMutableDictionary *mutableRequestParams = [model.data mutableCopy];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:self.requestUrl];
    NSMutableDictionary *queryItemsDic = [NSMutableDictionary new];
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [queryItemsDic cj_setObject:obj.value forKey:obj.name];
    }];
    // 1.1 用URL query中的参数替换掉Model中的data信息。
    [model.dataFields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([queryItemsDic cj_stringValueForKey:key] && [mutableRequestParams valueForKeyPath:obj]) {
            [mutableRequestParams cj_setValue:[queryItemsDic cj_stringValueForKey:key] forKeyPath:obj];
        } else {
            [mutableRequestParams cj_setValue:nil forKeyPath:obj];
        }
    }];
    // 1.2 将请求参数中的部分处理成JSONString.
    [model.dataToJSONKeyPaths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id curKeyPathValue = [mutableRequestParams valueForKeyPath:obj];
        if (curKeyPathValue) {
            if ([curKeyPathValue isKindOfClass:NSString.class]) {
                // 原始字符串，不作任何转化
            } else if ([curKeyPathValue isKindOfClass:NSDictionary.class]) {
                [mutableRequestParams cj_setValue:[CJPayCommonUtil dictionaryToJson:curKeyPathValue] forKeyPath:obj];
            } else if ([curKeyPathValue isKindOfClass:NSArray.class]) {
                [mutableRequestParams cj_setValue:[CJPayCommonUtil arrayToJson:curKeyPathValue] forKeyPath:obj];
            }
        }
    }];
    self.requestParams = [mutableRequestParams copy];
}

#pragma mark - CJPayPrefetcherProtocol
- (void)startRequest {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self p_processRequestData:self.config];
        
        if (self.curModel && Check_ValidString(self.curModel.api) && self.requestParams.count > 0) {
            CJPayRequestSerializeType type = CJPayRequestSerializeTypeURLEncode;
            if ([self.curModel.dataType isEqualToString:@"JSON"]) {
                type = CJPayRequestSerializeTypeJSON;
            }
            
            [CJPayBaseRequest startRequestWithUrl:self.curModel.api method:self.curModel.method requestParams:self.requestParams headerFields:@{} serializeType:type callback:^(NSError *error, id jsonObj) {
                self.error = error;
                self.data = jsonObj;
                self.dataReady = YES;
            } needCommonParams:YES];
        }
    });
}

// 数组操作都放到主线程里，避免线程安全问题
- (void)fetchData:(void (^)(id, NSError *))callback {
    if (self.dataReady) {
        CJ_CALL_BLOCK(callback, self.data, self.error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataCallbacks addObject:[callback copy]];
        });
    }
}

- (void)p_notifyDataReady {
    if (self.dataCallbacks.count > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataCallbacks enumerateObjectsUsingBlock:^(void (^ _Nonnull obj)(id, NSError *), NSUInteger idx, BOOL * _Nonnull stop) {
                CJ_CALL_BLOCK(obj, self.data, self.error);
            }];
            [self.dataCallbacks removeAllObjects];
        });
    }
}

- (void)setDataReady:(BOOL)dataReady {
    _dataReady = dataReady;
    [self p_notifyDataReady];
}

- (NSMutableArray *)dataCallbacks {
    if (!_dataCallbacks) {
        _dataCallbacks = [NSMutableArray new];
    }
    return _dataCallbacks;
}

@end

//
//  TTVideoEngine+SubTitle.m
//  TTVideoEngine
//
//  Created by haocheng on 2020/11/4.
//

#import "TTVideoEngine+SubTitle.h"
#import "TTVideoEngineNetwork.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngine+Private.h"
#import "NSDictionary+TTVideoEngine.h"

static
id checkNSNull(id obj) {
    return obj == [NSNull null] ? nil : obj;
}

@interface TTVideoEngineSubModel()

@property (nonatomic, assign) NSInteger languageId;
@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSString *format;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, assign) NSInteger expireTime;
@property (nonatomic, assign) NSInteger subtitleId;

@end

@implementation TTVideoEngineSubModel

- (instancetype)initWithDictionary:(NSDictionary * _Nonnull)dict {
    self = [super init];
    if (self) {
        NSNumber *language_id = checkNSNull(dict[kTTVideoEngineSubModelLangIdKey]);
        if (!language_id)
            return nil;
        self.languageId = [language_id integerValue];

        NSString *subtitleId = checkNSNull(dict[kTTVideoEngineSubModelSubtitleIdKey]);
        if (!subtitleId)
            return nil;
        self.subtitleId = [subtitleId integerValue];
        
        NSString *url = checkNSNull(dict[kTTVideoEngineSubModelURLKey]);
        if (!url || !url.length)
            return nil;
        self.urlString = url;

        NSString *format = checkNSNull(dict[kTTVideoEngineSubModelFormatKey]);
        if (!format || !format.length)
            return nil;
        self.format = format;

        self.index = [checkNSNull(dict[kTTVideoEngineSubModelIndexKey]) integerValue];
        self.language = checkNSNull(dict[kTTVideoEngineSubModelLanguageKey]);
        self.expireTime = [checkNSNull(dict[kTTVideoEngineSubModelExpireTimeKey]) integerValue];
    }
    return self;
}

- (NSDictionary *_Nullable)toDictionary {
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    [jsonDict setValue:@(self.index) forKey:kTTVideoEngineSubModelIndexKey];
    [jsonDict setValue:self.language forKey:kTTVideoEngineSubModelLanguageKey];
    [jsonDict setValue:@(self.subtitleId) forKey:kTTVideoEngineSubModelSubtitleIdKey];
    [jsonDict setValue:@(self.languageId) forKey:kTTVideoEngineSubModelLangIdKey];
    [jsonDict setValue:self.urlString forKey:kTTVideoEngineSubModelURLKey];
    [jsonDict setValue:@(self.expireTime) forKey:kTTVideoEngineSubModelExpireTimeKey];
    [jsonDict setValue:self.format forKey:kTTVideoEngineSubModelFormatKey];
    return jsonDict;
}

- (NSString *_Nullable)jsonString {
    if (!self.urlString.length || !self.format.length)
        return nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self toDictionary] options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end

@interface TTVideoEngineSubDecInfoModel()

@property (nonatomic, strong) NSMutableArray<id<TTVideoEngineSubProtocol>> *subModels;

@end

@implementation TTVideoEngineSubDecInfoModel

- (instancetype)initWithDictionary:(NSDictionary *_Nonnull)dict {
    self = [super init];
    if (self) {
        NSArray *models = checkNSNull(dict[kTTVideoEngineSubModelListKey]);
        if (models && models.count) {
            for (NSDictionary *sub in models) {
                TTVideoEngineSubModel *model = [[TTVideoEngineSubModel alloc] initWithDictionary:sub];
                if (model)
                    [self.subModels addObject:model];
            }
        }
    }
    return self;
}

- (instancetype)initWithSubModels:(NSArray<id<TTVideoEngineSubProtocol>> *_Nonnull)models {
    self = [super init];
    if (self) {
        for (id<TTVideoEngineSubProtocol> model in models) {
            NSDictionary *modelDict = [model toDictionary];
            if (checkNSNull(modelDict[kTTVideoEngineSubModelFormatKey])
                && checkNSNull(modelDict[kTTVideoEngineSubModelLangIdKey])
                && checkNSNull(modelDict[kTTVideoEngineSubModelURLKey])
                && checkNSNull(modelDict[kTTVideoEngineSubModelSubtitleIdKey]))
                [self.subModels addObject:model];
        }
    }
    return self;
}

- (void)addSubModel:(id<TTVideoEngineSubProtocol> _Nonnull)model {
    NSDictionary *modelDict = [model toDictionary];
    if (checkNSNull(modelDict[kTTVideoEngineSubModelFormatKey])
        && checkNSNull(modelDict[kTTVideoEngineSubModelLangIdKey])
        && checkNSNull(modelDict[kTTVideoEngineSubModelURLKey])
        && checkNSNull(modelDict[kTTVideoEngineSubModelSubtitleIdKey]))
        [self.subModels addObject:model];
}

- (NSString *_Nullable)jsonString {
    if (!self.subModels || !self.subModels.count)
        return nil;
    
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    NSMutableArray<NSDictionary *> *modelDicts = [NSMutableArray array];
    
    for (id<TTVideoEngineSubProtocol> model in self.subModels) {
        NSDictionary *modelDict = [model toDictionary];
        if (checkNSNull(modelDict[kTTVideoEngineSubModelFormatKey])
            && checkNSNull(modelDict[kTTVideoEngineSubModelLangIdKey])
            && checkNSNull(modelDict[kTTVideoEngineSubModelURLKey])
            && checkNSNull(modelDict[kTTVideoEngineSubModelSubtitleIdKey]))
            [modelDicts addObject:[model toDictionary]];
    }
    
    [jsonDict setValue:modelDicts forKey:kTTVideoEngineSubModelListKey];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (NSInteger)subtitleCount {
    return self.subModels.count;
}

- (NSMutableArray<id<TTVideoEngineSubProtocol>> *)subModels {
    if (_subModels == nil) {
        _subModels = [NSMutableArray array];
    }
    return _subModels;
}


@end

@implementation TTVideoEngineSubInfo

@end

@implementation TTVideoEngineLoadInfo

@end

@implementation TTVideoEngine (SubTitle)

- (NSString *_Nullable)_getSubtitleUrlWithHostName:(NSString *)hostName
                                               vid:(NSString *)vid
                                            fileId:(NSString *)fileId
                                          language:(nullable NSString *)language
                                            format:(nullable NSString *)format {
    if (!hostName.length || !vid.length || !fileId.length) return nil;
    //host url
    if(!([hostName hasPrefix:@"https://"] || [hostName hasPrefix:@"http://"])){
        hostName = [@"https://" stringByAppendingString:hostName];
    }
    if (self.boeEnable) {
        hostName = TTVideoEngineBuildBoeUrl(hostName);
    }
    NSString *requestUrlString = [NSString stringWithFormat:@"%@/video/subtitle/v1/%@/%@?", hostName, vid, fileId];
    
    NSMutableArray<NSString *> *queryArr = [NSMutableArray array];
    //language query
    if (language.length) {
        NSString *languageQuery = [NSString stringWithFormat:@"sub_ids=%@", language];
        [queryArr addObject:languageQuery];
    }
    //format query
    if (format.length) {
        NSString *formatQuery = [NSString stringWithFormat:@"format=%@", format];
        [queryArr addObject:formatQuery];
    }
    
    //using url
    for (int i = 0; i < queryArr.count; i++) {
        if (!queryArr[i].length)
            continue;
        if (i > 0)
            requestUrlString = [requestUrlString stringByAppendingString:@"&"];
        requestUrlString = [requestUrlString stringByAppendingString:queryArr[i]];
    }
    
    return requestUrlString;
}

- (void)_requestSubtitleInfoWithUrlString:(NSString *)urlString
                                 handler:(void (^)(NSString * _Nullable, NSError * _Nullable))handler
{
    @weakify(self)
    void (^completeHandler)(id  _Nullable jsonObject, NSError * _Nullable error) = ^(id  _Nullable jsonObject, NSError * _Nullable error){
        @strongify(self)
        //request info call back
        if (self.subtitleDelegate && [self.subtitleDelegate respondsToSelector:@selector(videoEngine:onSubtitleInfoRequested:error:)]) {
            [self.subtitleDelegate videoEngine:self onSubtitleInfoRequested:jsonObject error:error];
        }
        
        //load result call back
        if (self.subtitleDelegate && [self.subtitleDelegate respondsToSelector:@selector(videoEngine:onSubLoadFinished:)]) {
            [self.subtitleDelegate videoEngine:self onSubLoadFinished:NO];
        }
        
        //error
        if (error != nil) {
            if (handler) {
                handler(nil, error);
            }
            return;
        }
        
        if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            self.subtitleInfo = jsonObject;
        }
        
        NSString *jsonResult = nil;
        NSDictionary *result = [jsonObject ttVideoEngineDictionaryValueForKey:@"data" defaultValue:nil];
        if (result.count) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
            jsonResult = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        if (handler) {
            handler(jsonResult, nil);
        }
    };
    
    if (!urlString.length) return;
    NSURL *url = [NSURL URLWithString:urlString];
    id<TTVideoEngineNetClient> client = nil;
    if (self.netClient) {
        client = self.netClient;
    } else {
        client = self.subtitleNetworkClient;
    }
    
    if ([client respondsToSelector:@selector(configTaskWithURL:params:headers:completion:)]) {
        [client configTaskWithURL:url
                           params:nil
                          headers:nil
                       completion:completeHandler];
    } else if ([client respondsToSelector:@selector(configTaskWithURL:params:completion:)]) {
        [client configTaskWithURL:url
                           params:nil
                       completion:completeHandler];
    }
    [client resume];
}

- (NSDictionary * _Nullable)requestedSubtitleInfo {
    return self.subtitleInfo;
}

+ (void)requestSubtitleInfoWith:(NSString * _Nonnull)hostName
                            vid:(NSString * _Nonnull)vid
                         fileId:(NSString * _Nonnull)fileId
                       language:(NSString * _Nullable)language
                         client:(id<TTVideoEngineNetClient> _Nullable)client
                     completion:(nullable void (^)(id _Nullable jsonObject, NSError * _Nullable error))completionHandler {
    if (!hostName.length || !vid.length || !fileId.length) return;
    //host url
    if(!([hostName hasPrefix:@"https://"] || [hostName hasPrefix:@"http://"])){
        hostName = [@"http://" stringByAppendingString:hostName];
    }
    NSString *fontPartString = [NSString stringWithFormat:@"%@/video/subtitle/v1/%@/%@?", hostName, vid, fileId];
    //query
    NSString *queryString = @"";
    if (language.length) {
        queryString = [NSString stringWithFormat:@"languages=%@", language];
    }
    //using url
    NSString *requestUrlString = [fontPartString stringByAppendingString:queryString];
    
    void (^completeHandler)(id  _Nullable jsonObject, NSError * _Nullable error) = ^(id  _Nullable jsonObject, NSError * _Nullable error){
        if (completionHandler) {
            completionHandler(jsonObject, error);
        }
    };
    
    if (!requestUrlString.length) return;
    NSURL *url = [NSURL URLWithString:requestUrlString];
    id<TTVideoEngineNetClient> requestClient = nil;
    if (client) {
        requestClient = client;
    } else {
        requestClient = [[TTVideoEngineNetwork alloc] initWithTimeout:10.0];
    }
    
    if ([requestClient respondsToSelector:@selector(configTaskWithURL:params:headers:completion:)]) {
        [requestClient configTaskWithURL:url
                           params:nil
                          headers:nil
                       completion:completeHandler];
    } else if ([requestClient respondsToSelector:@selector(configTaskWithURL:params:completion:)]) {
        [requestClient configTaskWithURL:url
                           params:nil
                       completion:completeHandler];
    }
    [requestClient resume];
}

@end

//
//  QueryFilterEngine.m
//  TTNetworkManager
//
//  Created by dongyangfan on 2021/6/18.
//

#import "QueryFilterEngine.h"
#import "QueryFilterAction.h"
#import "QueryFilterResult.h"
#import "TTNetworkManagerLog.h"
#import "TTNetworkDefine.h"
#import "TTNetworkManagerChromium.h"
#import <BDDataDecorator/NSData+DataDecorator.h>

//encrypt bosy  max size = 100KB
#define kEncryptBodyMaxSize 102400

//header,body,or header+body
typedef NS_ENUM(int, EncryptType) {
    ENCRYPT_QUERY = 0,
    ENCRYPT_BODY,
    ENCRYPT_QUERY_BODY,
    ENCRYPT_NONE
};

#define kEncryptHeaderCipherVersionKey  @"x-tt-cipher-version"
#define kEncryptHeaderCipherVersionValue  @"1.0.0"
#define kEncryptHeaderCipherInfoKey @"x-tt-encrypt-info"
#define kEncryptHeaderQueriesKey @"x-tt-encrypt-queries"


@interface QueryFilterEngine()

@property (atomic, strong) NSMutableArray<QueryFilterAction *> *filterActions;

@property (atomic, assign) BOOL queryFilterEnabled;

@end


@implementation QueryFilterEngine

+ (instancetype)shareInstance {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (id)init {
    self = [super init];
    if (self) {
        _queryFilterEnabled = NO;
    }
    return self;
}

//called by user when app start
- (void)setLocalCommonParamsConfig:(NSString *)contentString {
    NSData *data = [contentString dataUsingEncoding: NSUTF8StringEncoding];
    if (!data) {
        LOGE(@"contentString invalid: %@", contentString);
        return;
    }
    
    NSError *jsonError = nil;
    id jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (!jsonError && [jsonDict isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = (NSDictionary *)jsonDict;
        NSDictionary *data = [dict objectForKey:kTNCData];
        if (![data isKindOfClass:NSDictionary.class]) {
            LOGE(@"data is not NSDictionary");
            return;
        }
        
        [self parseTNCQueryFilterConfig:data];
    } else {
        LOGE(@"Local common params config invalid: %@", contentString);
        return;
    }
}

- (NSString *)filterQuery:(TTHttpRequestChromium *)originalRequest {
    NSString *originalUrlStr = originalRequest.urlString;
    if (!self.queryFilterEnabled) {
        return originalUrlStr;
    }
    
    if (!self.filterActions || [self.filterActions count] == 0) {
        return originalUrlStr;
    }
    
    if (originalRequest.pureRequest) {
        return originalUrlStr;
    }
    
    //put original query to dictionary
    NSRange queryRange = [originalUrlStr rangeOfString:@"?"];
    QueryFilterObject *queryMap = nil;
    NSString *fragment = nil;
    if (queryRange.location == NSNotFound) {
        return originalUrlStr;
    } else {
        NSURL *nsurl = [NSURL URLWithString:originalUrlStr];
        fragment = nsurl.fragment;
        if (!nsurl.query) {
            //handle url which # appears before ?
            //# may still appear after ?
            NSString *fuzzyQuery = [originalUrlStr substringFromIndex:queryRange.location + 1];
            NSRange realFragmentRange = [fuzzyQuery rangeOfString:@"#"];
            NSString *filteredUrl = nil;
            if (realFragmentRange.location == NSNotFound) {
                NSString *filteredQuery = [self.class filterQueryStringWithL0Params:fuzzyQuery];
                if (!filteredQuery) {
                    filteredUrl = [originalUrlStr substringToIndex:queryRange.location];
                } else {
                    filteredUrl = [NSString stringWithFormat:@"%@?%@", [originalUrlStr substringToIndex:queryRange.location], filteredQuery];
                }
            } else {
                NSString *realQuery = [fuzzyQuery substringToIndex:realFragmentRange.location];
                NSString *realFragment = [fuzzyQuery substringFromIndex:realFragmentRange.location + 1];
                NSString *filteredQuery = [self.class filterQueryStringWithL0Params:realQuery];
                if (!filteredQuery) {
                    filteredUrl = [NSString stringWithFormat:@"%@#%@", [originalUrlStr substringToIndex:queryRange.location], realFragment];
                } else {
                    filteredUrl = [NSString stringWithFormat:@"%@?%@#%@", [originalUrlStr substringToIndex:queryRange.location], filteredQuery, realFragment];
                }
            }
            return filteredUrl;
        }
    }
    
    NSMutableArray *filterActions = self.filterActions;
    QueryFilterResult *filterResult = nil;
    
    for (QueryFilterAction *item in filterActions) {
        NSInteger reqPriority = originalRequest.requestQueryPriority;
        NSInteger tmpPriority = reqPriority;
        BOOL isHit = NO;
        [item takeAction:&queryMap withUrlString:originalUrlStr reqPriority:&reqPriority isHit:&isHit queryFilterResult:&filterResult];
        
        if (isHit) {
            if (tmpPriority != reqPriority) {
                originalRequest.requestQueryPriority = reqPriority;
            }
                
            if ([item getRequestPriority] == -1) {
                break;
            }
        }
    }
    
    //didn't hit any action or didn't change in action
    if (!filterResult) {
        return originalUrlStr;
    }
    
    [self.class handleQueryBodyEncryptIfNeed:originalRequest queryMap:queryMap withFilterResult:filterResult];
    
    //remove query
    NSMutableArray *mutableQueryPairArray = [NSMutableArray arrayWithArray:queryMap.queryPairArray];
    //indexes to be removed
    NSMutableIndexSet *mergeIndexSet = [[NSMutableIndexSet alloc] init];
    if (filterResult.removingIndexSet) {
        [mergeIndexSet addIndexes:filterResult.removingIndexSet];
    }
        
    if (filterResult.queryEncryptIndexSet) {
        [mergeIndexSet addIndexes:filterResult.queryEncryptIndexSet];
    }
    if (mergeIndexSet.count > 0) {
        [mutableQueryPairArray removeObjectsAtIndexes:mergeIndexSet];
        queryMap.queryPairArray = mutableQueryPairArray;
    }
    
    NSString *offQueryURLString = [originalUrlStr substringToIndex:queryRange.location];
    NSString *finalQuery = [self.class queryStringFromPairArray:queryMap.queryPairArray];
    NSString *output = [NSString stringWithFormat:@"%@%@", offQueryURLString, finalQuery];
    if (fragment) {
        output = [NSString stringWithFormat:@"%@#%@", output, fragment];
    }
    
    return output;
}

+ (void)handleQueryBodyEncryptIfNeed:(TTHttpRequestChromium *)originalRequest
                            queryMap:(QueryFilterObject *)queryMap
                    withFilterResult:(QueryFilterResult *)filterResult {
    //====================handle query encrypt====================//
    NSString *encryptedQueryBase64Encode = nil;
    BOOL isQueryEncrypted = NO;
    if (filterResult.queryEncryptIndexSet) {
        NSArray<QueryPairObject *> *needEncryptArray = [queryMap.queryPairArray objectsAtIndexes:filterResult.queryEncryptIndexSet];
        //remove the first character:?
        NSString *queryNeedEncryptString = [[self.class queryStringFromPairArray:needEncryptArray] substringFromIndex:1];
        NSData *queryData = [queryNeedEncryptString dataUsingEncoding:NSUTF8StringEncoding];
        NSData *encryptedData = [queryData bd_dataByDecorated];
        if (encryptedData) {
            encryptedQueryBase64Encode = base64EncodedString(encryptedData);
            isQueryEncrypted = YES;
        } else {
            LOGE(@"encrypt query failed!");
        }
    }
    
    //==============handle body encrypt===================//
    BOOL isBodyEncrypted = NO;
    if (filterResult.bodyEncryptEnabled) {
        NSString *httpMethod = [originalRequest.HTTPMethod lowercaseString];
        BOOL isPost = [httpMethod isEqualToString:@"post"] || [httpMethod isEqualToString:@"put"];
        NSInteger bodySize = [originalRequest.HTTPBody length];
        if (isPost && bodySize <= kEncryptBodyMaxSize && bodySize > 0) {
            NSData *encryptBody = [originalRequest.HTTPBody bd_dataByDecorated];
            if (encryptBody) {
                [originalRequest setHTTPBody:encryptBody];
                isBodyEncrypted = YES;
            } else {
                LOGE(@"encrypt body failed!");
            }
        }
    }
    
    //==============add encrypt related header===============//
    EncryptType encrypt = [self.class getEncryptTypeFromQueryEncrypt:isQueryEncrypted bodyEncrypt:isBodyEncrypted];
    switch (encrypt) {
        case ENCRYPT_QUERY_BODY:
            {
                [originalRequest setValue:kEncryptHeaderCipherVersionValue forHTTPHeaderField:kEncryptHeaderCipherVersionKey];
                [originalRequest setValue:@"2" forHTTPHeaderField:kEncryptHeaderCipherInfoKey];
                [originalRequest setValue:encryptedQueryBase64Encode forHTTPHeaderField:kEncryptHeaderQueriesKey];
            }
            break;
            
        case ENCRYPT_QUERY:
            {
                [originalRequest setValue:kEncryptHeaderCipherVersionValue forHTTPHeaderField:kEncryptHeaderCipherVersionKey];
                [originalRequest setValue:@"0" forHTTPHeaderField:kEncryptHeaderCipherInfoKey];
                [originalRequest setValue:encryptedQueryBase64Encode forHTTPHeaderField:kEncryptHeaderQueriesKey];
            }
            break;
            
        case ENCRYPT_BODY:
            {
                [originalRequest setValue:kEncryptHeaderCipherVersionValue forHTTPHeaderField:kEncryptHeaderCipherVersionKey];
                [originalRequest setValue:@"1" forHTTPHeaderField:kEncryptHeaderCipherInfoKey];
            }
            break;
            
        case ENCRYPT_NONE:
            break;
            
        default:
            break;
    }
}

+ (EncryptType)getEncryptTypeFromQueryEncrypt:(BOOL)isQueryEncrypted bodyEncrypt:(BOOL)isBodyEncrypted {
    if (isQueryEncrypted && isBodyEncrypted) {
        return ENCRYPT_QUERY_BODY;
    }
    
    if (isQueryEncrypted) {
        return ENCRYPT_QUERY;
    }
    
    if (isBodyEncrypted) {
        return ENCRYPT_BODY;
    }
    
    return ENCRYPT_NONE;
}

+ (NSString *)queryStringFromPairArray:(NSArray<QueryPairObject *> *)pairArray {
    if (!pairArray) {
        return nil;
    }
    NSMutableString *finalQuery = [NSMutableString new];
    NSString *sep = @"?";
    for (QueryPairObject *pair in pairArray) {
        NSString *key = pair.key;
        NSString *value = pair.value;
        
        if ([key isEqualToString:kTTNetQueryFilterReservedKey]) {
            [finalQuery appendFormat:@"%@%@", sep, value];
        } else {
            [finalQuery appendFormat:@"%@%@=%@", sep, key, value];
        }
        
        if ([sep isEqualToString:@"?"]) {
            sep = @"&";
        }
    }
    return finalQuery;
}

+ (NSString *)filterQueryStringWithL0Params:(NSString *)originalQueryString {
    QueryFilterObject *queryFilterObject = [QueryFilterAction convertQueryStringWithOrder:originalQueryString];
    if (!queryFilterObject) {
        return originalQueryString;
    }
    NSArray *paramsL0 = ((TTNetworkManagerChromium *)[TTNetworkManager shareInstance]).commonParamsL0Level;
    if (!paramsL0) {
        return originalQueryString;
    }
    
    NSMutableIndexSet *removingIndexSet = nil; //all indexes to be removed from queryPairArray
    for (NSString *param in paramsL0) {
        NSArray *indexesToBeRemoved = [queryFilterObject.keyAndIndexDict objectForKey:param];
        if (indexesToBeRemoved) {
            if (!removingIndexSet) {
                removingIndexSet = [[NSMutableIndexSet alloc] init];
            }
            for (id obj in indexesToBeRemoved) {
                NSNumber *num = (NSNumber *)obj;
                NSUInteger removeIndex = num.unsignedLongValue;
                [removingIndexSet addIndex:removeIndex];
            }
        }
    }
    
    if (!removingIndexSet || removingIndexSet.count == 0) {
        return originalQueryString;
    }
    
    NSMutableArray *mutableQueryPairArray = [NSMutableArray arrayWithArray:queryFilterObject.queryPairArray];
    [mutableQueryPairArray removeObjectsAtIndexes:removingIndexSet];
    queryFilterObject.queryPairArray = mutableQueryPairArray;
    
    NSMutableString *filteredQuery = nil;
    if (queryFilterObject.queryPairArray && queryFilterObject.queryPairArray.count > 0) {
        NSString *sep = @"";
        filteredQuery = [NSMutableString new];
        for (QueryPairObject *pair in queryFilterObject.queryPairArray) {
            NSString *key = pair.key;
            NSString *value = pair.value;
            
            if ([key isEqualToString:kTTNetQueryFilterReservedKey]) {
                [filteredQuery appendFormat:@"%@%@", sep, value];
            } else {
                [filteredQuery appendFormat:@"%@%@=%@", sep, key, value];
            }
            
            if ([sep isEqualToString:@""]) {
                sep = @"&";
            }
        }
    }
    //return nil if all query keys are L0
    return filteredQuery;
}

- (void)parseTNCQueryFilterConfig:(NSDictionary *)data {
    //reset
    self.queryFilterEnabled = NO;
    self.filterActions = nil;
    
    NSInteger filterEngineEnabled = 0;
    BOOL valueExistInJSON = NO;
    id filterEngineEnabledValue = [data objectForKey:kTNCQueryFilterEnabled];
    if (filterEngineEnabledValue && [filterEngineEnabledValue isKindOfClass:[NSString class]]) {
        filterEngineEnabled = [(NSString *)filterEngineEnabledValue intValue];
        valueExistInJSON = YES;
    } else if (filterEngineEnabledValue && [filterEngineEnabledValue isKindOfClass:[NSNumber class]]) {
        filterEngineEnabled = [(NSNumber *)filterEngineEnabledValue intValue];
        valueExistInJSON = YES;
    }
    
    if (valueExistInJSON) {
        self.queryFilterEnabled = filterEngineEnabled > 0;
    }
    
    if (filterEngineEnabled > 0) {
        id filterEngineConfig = [data objectForKey:kTNCQueryFilterActions];
        if (filterEngineConfig && [filterEngineConfig isKindOfClass:NSArray.class]) {
            [self parseQueryFilterConfig:filterEngineConfig];
        }
    }
}

- (void)parseQueryFilterConfig:(NSArray *)configJSONArray {
    NSMutableArray<QueryFilterAction *> *filterActions = nil;
    for (id item in configJSONArray) {
        if ([item isKindOfClass:NSDictionary.class]) {
            NSDictionary *value = (NSDictionary *)item;
            QueryFilterAction *filterAction = [[[QueryFilterAction alloc] init] parseActionFromDict:value];
            if (!filterActions) {
                filterActions = [[NSMutableArray alloc] init];
            }
            [filterActions addObject:filterAction];
            LOGD(@"+++add filterAction:%ld", filterAction.getRequestPriority);
        }
    }
    
    //sort according to act_priority
    if (filterActions && filterActions.count > 0) {
        NSSortDescriptor *actPrioritySorter = [NSSortDescriptor sortDescriptorWithKey:@"actionPriority" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&actPrioritySorter count:1];
        [filterActions sortUsingDescriptors:sortDescriptors];
    }
    
    self.filterActions = filterActions;
}

@end

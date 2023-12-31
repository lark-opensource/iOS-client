//
//  QueryFilterAction.m
//  TTNetworkManager
//
//  Created by dongyangfan on 2021/6/18.
//

#import "QueryFilterAction.h"
#import "QueryFilterResult.h"
#import "TTNetworkDefine.h"
#import "TTNetworkManagerLog.h"

typedef NS_ENUM(int, QueryActionType) {
    ENCRYPT = 0,
    REMOVE,
};

@interface QueryFilterAction()

@property (nonatomic, copy) NSString *action;

@property (nonatomic, assign) NSInteger actionPriority;

@property (nonatomic, assign) NSInteger setReqPriority;

@property (nonatomic, strong) NSArray<NSString *> *hostGroup;

@property (nonatomic, strong) NSArray<NSString *> *pathEqualGroup;

@property (nonatomic, strong) NSArray<NSString *> *pathPrefixGroup;

@property (nonatomic, strong) NSArray<NSString *> *pathPatternGroup;

@property (nonatomic, strong) NSArray<NSString *> *removeList;

@property (nonatomic, strong) NSArray<NSString *> *keepList;

@property (nonatomic, strong) NSArray<NSString *> *addList;

//for sensitive query and body encrypt
@property (nonatomic, strong) NSArray<NSString *> *encryptQueryList;

@property (nonatomic, assign) BOOL bodyEncryptEnabled;

@end


@implementation QueryFilterAction

- (instancetype)initWithAction:(NSString *)action
                   actPriority:(NSInteger)actPriority
                     hostGroup:(NSArray<NSString *> *)hostGroup {
    if (self = [super init]) {
        self.action = action;
        self.actionPriority = actPriority;
        self.setReqPriority = 0;
        self.hostGroup = hostGroup;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        self.setReqPriority = 0;
    }
    return self;
}

- (QueryFilterAction *)parseActionFromDict:(NSDictionary *)configValue {
    //action and act_priority
    NSString *action = [configValue objectForKey:kTNCAction];
    NSInteger actPriority = [[configValue objectForKey:kTNCActionPriority] integerValue];
    //param
    NSDictionary *paramValue = [configValue objectForKey:kTNCParam];
    NSArray *groups = [paramValue objectForKey:kTNCHostGroup];
    
    QueryFilterAction *filterAction = [[QueryFilterAction alloc] initWithAction:action actPriority:actPriority hostGroup:groups];
    
    NSInteger setReqPriority = [[configValue objectForKey:kTNCSetReqPriority] integerValue];
    filterAction.setReqPriority = setReqPriority;
    //path
    groups = [paramValue objectForKey:kTNCPrefixGroup];
    filterAction.pathPrefixGroup = groups;
    groups = [paramValue objectForKey:kTNCEqualGroup];
    filterAction.pathEqualGroup = groups;
    groups = [paramValue objectForKey:kTNCPatternGroup];
    filterAction.pathPatternGroup = groups;
    
    //list
    groups = [paramValue objectForKey:kTNCRemoveList];
    filterAction.removeList = groups;
    groups = [paramValue objectForKey:kTNCAddList];
    filterAction.addList = groups;
    groups = [paramValue objectForKey:kTNCKeepList];
    filterAction.keepList = groups;
    
    //query and body encrypt
    groups = [paramValue objectForKey:kTNCEncryptQueryList];
    filterAction.encryptQueryList = groups;
    
    NSNumber *bodyEncryptEnabled = [paramValue objectForKey:kTNCEncryptBodyEnabled];
    if (bodyEncryptEnabled) {
        filterAction.bodyEncryptEnabled = [bodyEncryptEnabled integerValue] > 0;
    }
    
    return filterAction;
}

- (void)takeAction:(QueryFilterObject **)originalQueryMap
     withUrlString:(NSString *)originalUrlString
       reqPriority:(NSInteger *)reqPriority
             isHit:(BOOL *)isHit
 queryFilterResult:(QueryFilterResult **)filterResult {
    NSURL *URL = [NSURL URLWithString:originalUrlString];
    NSString *host = URL.host;
    NSString *path = URL.path;
    NSString *queryString = URL.query;
    
    BOOL hitRules = (!self.hostGroup) || ([TTNetworkUtil isMatching:host pattern:kCommonMatch source:self.hostGroup]); //host hit
    if (!hitRules || !path) {
        //host Not match
        return;
    }
    
    NSUInteger len = [path length];
    if (len > 1 && [path hasSuffix:@"/"]) {
        path = [path substringToIndex:len - 1];
    }
    
    if ([TTNetworkUtil isMatching:path pattern:kPathEqualMatch source:self.pathEqualGroup] ||
        [TTNetworkUtil isMatching:path pattern:kPathPrefixMatch source:self.pathPrefixGroup] ||
        [TTNetworkUtil isMatching:path pattern:kPathPatternMatch source:self.pathPatternGroup]) {
        [self doActionInternal:originalQueryMap
               withQueryString:queryString
                   reqPriority:reqPriority
                         isHit:isHit
             queryFilterResult:filterResult];
    }
}

- (void)doActionInternal:(QueryFilterObject **)originalQueryMap
         withQueryString:(NSString *)originalQueryString
             reqPriority:(NSInteger *)reqPriority
                   isHit:(BOOL *)isHit
       queryFilterResult:(QueryFilterResult **)filterResult {
    if ((self.actionPriority < 0) || (*reqPriority > self.actionPriority)) {
        return;
    }
    
    if ([self.action isEqualToString:kTNCActionRemove]) {
        if (self.keepList && self.removeList) {
            LOGE(@"keepList and removeList both exist, action won't take effect");
            return;
        }
        
        if (self.keepList || self.removeList) {
            //lazy init
            if (!*originalQueryMap) {
                *originalQueryMap = [self.class convertQueryStringWithOrder:originalQueryString];
            }
        }
        
        if (self.removeList) {
            [self removeQuery:*originalQueryMap
             according2RmList:self.removeList
            queryFilterResult:filterResult];
        }
        
        if (self.keepList) {
            [self removeQuery:*originalQueryMap
           according2KeepList:self.keepList
            queryFilterResult:filterResult];
        }
        
        *reqPriority = (self.setReqPriority == 0 ? self.actionPriority : self.setReqPriority);
        *isHit = YES;
    } else if ([self.action isEqualToString:kTNCActionAdd]) {
        //Not support add now
        LOGI(@"add action not support now");
        *isHit = YES;
    } else if ([self.action isEqualToString:kTNCActionEncrypt]) {
        if (self.encryptQueryList || self.bodyEncryptEnabled) {
            //lazy init
            if (!*originalQueryMap) {
                *originalQueryMap = [self.class convertQueryStringWithOrder:originalQueryString];
            }
            
            [self markQueryIndex:*originalQueryMap
                  according2List:self.encryptQueryList
                    filterResult:filterResult
                      actionType:ENCRYPT];
            
            if (self.bodyEncryptEnabled) {
                if (!*filterResult) {
                    *filterResult = [[QueryFilterResult alloc] init];
                }
                
                if (!(*filterResult).bodyEncryptEnabled) {
                    (*filterResult).bodyEncryptEnabled = YES;
                }
            }
            
            *reqPriority = (self.setReqPriority == 0 ? self.actionPriority : self.setReqPriority);
            *isHit = YES;
        }
    } else {
        LOGE(@"unsupport action");
    }
}

- (NSInteger)getRequestPriority {
    return self.setReqPriority;
}

- (void)markQueryIndex:(QueryFilterObject *)originalQueryMap
        according2List:(NSArray<NSString *> *)list
          filterResult:(QueryFilterResult **)filterResult
            actionType:(QueryActionType)actionType {
    if (!originalQueryMap || !list) {
        return;
    }
    
    for (NSString *key in list) {
        NSArray *indexes = [originalQueryMap.keyAndIndexDict objectForKey:key];
        
        if (!indexes) {
            continue;
        }
        
        if (!*filterResult) {
            *filterResult = [[QueryFilterResult alloc] init];
        }
        
        switch (actionType) {
            case ENCRYPT:
                {
                    if (!(*filterResult).queryEncryptIndexSet) {
                        (*filterResult).queryEncryptIndexSet = [[NSMutableIndexSet alloc] init];
                    }
                        
                    for (id obj in indexes) {
                        NSNumber *num = (NSNumber *)obj;
                        NSUInteger encryptIndex = num.unsignedLongValue;
                        [(*filterResult).queryEncryptIndexSet addIndex:encryptIndex];
                    }
                }
                break;
                
            case REMOVE:
                {
                    if (!(*filterResult).removingIndexSet) {
                        (*filterResult).removingIndexSet = [[NSMutableIndexSet alloc] init];
                    }
                        
                    for (id obj in indexes) {
                        NSNumber *num = (NSNumber *)obj;
                        NSUInteger removeIndex = num.unsignedLongValue;
                        [(*filterResult).removingIndexSet addIndex:removeIndex];
                    }
                }
                break;
                
            default:
                break;
        }
    }
}


- (void)removeQuery:(QueryFilterObject *)originalQueryMap
   according2RmList:(NSArray<NSString *> *)removeList
  queryFilterResult:(QueryFilterResult **)filterResult {
    [self markQueryIndex:originalQueryMap
          according2List:removeList
            filterResult:filterResult
              actionType:REMOVE];
}

- (void)removeQuery:(QueryFilterObject *)originalQueryMap
 according2KeepList:(NSArray<NSString *> *)keepList
  queryFilterResult:(QueryFilterResult **)filterResult {
    if (!originalQueryMap || !keepList) {
        return;
    }
    
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray:[originalQueryMap.keyAndIndexDict allKeys]];
    [allKeys removeObjectsInArray:keepList];
    [self removeQuery:originalQueryMap
     according2RmList:allKeys
    queryFilterResult:filterResult];
}

+ (QueryFilterObject *)convertQueryStringWithOrder:(NSString *)queryString {
    if (!queryString) {
        return nil;
    }
    
    NSArray *queryKVs = [queryString componentsSeparatedByString:@"&"];
    NSMutableArray<QueryPairObject *> *queryPairArray = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSArray *> *keyAndIndexDict = [NSMutableDictionary dictionary];
    NSUInteger indexNumber = 0;
    for (NSString *kvItem in queryKVs) {
        NSString *key, *value;
        NSRange queryRange = [kvItem rangeOfString:@"="];
        if (queryRange.location == NSNotFound) {
            //if item is NOT a valid query string,put it to kTTNetQueryFilterReservedKey
            key = kTTNetQueryFilterReservedKey;
            value = kvItem;
        } else {
            key = [kvItem substringToIndex:queryRange.location];
            value = [kvItem substringFromIndex:queryRange.location + 1];
        }
        
        QueryPairObject *queryPair = [[QueryPairObject alloc] initWithKey:key value:value];
        [queryPairArray addObject:queryPair];
            
        if (![keyAndIndexDict objectForKey:key]) {
            [keyAndIndexDict setObject:@[@(indexNumber)] forKey:key];
        } else {
            NSMutableArray *mValueArray = [NSMutableArray arrayWithArray:[keyAndIndexDict objectForKey:key]];
            [mValueArray addObject:@(indexNumber)];
            [keyAndIndexDict setObject:[mValueArray copy] forKey:key];
        }
        
        ++indexNumber;
    }
    
    QueryFilterObject *queryFilterObject = [[QueryFilterObject alloc] initWithQueryPairArray:queryPairArray
                                                                             keyAndIndexDict:keyAndIndexDict];
    return queryFilterObject;
}

@end

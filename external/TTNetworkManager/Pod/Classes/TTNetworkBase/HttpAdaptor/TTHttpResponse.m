//
//  TTHttpResponse.m
//  Pods
//
//  Created by gaohaidong on 9/22/16.
//
//

#import "TTHttpResponse.h"

@interface TTHttpResponse()
@property (atomic, readwrite, assign) BOOL isCallbackExecutedOnMainThread;
@end

@implementation TTCaseInsenstiveDictionary

- (instancetype)init {
    self = [super init];
    if (self) {
        inner_dict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithObjects:(id  _Nonnull const [])objects forKeys:(id<NSCopying>  _Nonnull const [])keys count:(NSUInteger)cnt {
    self = [super init];
    if (self) {
        inner_dict = [NSMutableDictionary dictionaryWithObjects:objects forKeys:keys count:cnt];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary {
    self = [super init];
    if (self) {
        inner_dict = [otherDictionary mutableCopy];
    }
    return self;
}

- (NSUInteger)count {
    return [inner_dict count];
}

- (id)objectForKey:(id)aKey {
    id ret = [inner_dict objectForKey:aKey];
    if (!ret && [aKey isKindOfClass:NSString.class]) {
        NSString *key = (NSString *)aKey;
        
        for (NSString *inkey in [inner_dict allKeys]) {
            if (![inkey isKindOfClass:NSString.class]) {
                continue;
            }
            if ([[inkey lowercaseString] isEqualToString: [key lowercaseString]]) {
                ret = inner_dict[inkey];
            }
        }
    }
    return ret;
}

- (NSEnumerator *)keyEnumerator {
    return [inner_dict keyEnumerator];
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (anObject && aKey) {
        [inner_dict setObject:anObject forKey:aKey];
    }
}

- (void)removeObjectForKey:(id)aKey {
    [inner_dict removeObjectForKey:aKey];
}

@end

@interface TTHttpResponse()
@property (nullable, readwrite, strong) NSMutableDictionary<NSString *, NSNumber *> *filterObjectsTimeInfo;

@property (nonnull, readwrite, strong) NSMutableDictionary<NSString *, NSNumber *> *serializerTimeInfo;

@property (nullable, readwrite, strong) TTHttpResponseAdditionalTimeInfo *additionalTimeInfo;

@property (nonnull, readwrite, strong) NSMutableDictionary *extraBizInfo;
@end

@implementation TTHttpResponse
- (instancetype)init {
    self = [super init];
    if (self) {
        self.filterObjectsTimeInfo = [NSMutableDictionary dictionary];
        self.serializerTimeInfo = [NSMutableDictionary dictionary];
        self.additionalTimeInfo = [[TTHttpResponseAdditionalTimeInfo alloc] initWithCompletionBlockTime:[NSMutableDictionary dictionary]];
        self.extraBizInfo = [NSMutableDictionary dictionary];
    }
    return self;
}
@end

@implementation TTHttpResponseTimingInfo

@end


@interface BDTuringCallbackInfo()
@property (nonatomic, assign, readwrite) int8_t bdTuringRetry;
@property (nonatomic, assign, readwrite) NSTimeInterval bdTuringCallbackDuration;
@end

@implementation BDTuringCallbackInfo

- (instancetype)initWithTuringRetry:(int8_t)turingRetry
                   callbackDuration:(NSTimeInterval)callbackDuration {
    if (self = [super init]) {
        self.bdTuringRetry = turingRetry;
        self.bdTuringCallbackDuration = callbackDuration;
    }
    return self;
}

@end


@implementation TTHttpResponseAdditionalTimeInfo

- (instancetype)initWithCompletionBlockTime:(NSMutableDictionary<NSString *, NSNumber *> *)completionBlockTime {
    if (self = [super init]) {
        if (!completionBlockTime) {
            self.completionBlockTime = [NSMutableDictionary dictionary];
        } else {
            self.completionBlockTime = completionBlockTime;
        }
    }
    return self;
}

@end

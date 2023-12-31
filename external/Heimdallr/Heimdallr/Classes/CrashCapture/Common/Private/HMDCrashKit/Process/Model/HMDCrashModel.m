//
//  HMDCrashModel.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashModel.h"
#import "HMDMacro.h"

@implementation HMDCrashModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    DEBUG_ASSERT(dict == nil || [dict isKindOfClass:NSDictionary.class]);
    
    if (unlikely(![dict isKindOfClass:NSDictionary.class])) {
        dict = nil;
    }
    
    if (self = [super init]) {
        [self updateWithDictionary:dict];
    }
    
    return self;
}

+ (instancetype)objectWithDictionary:(NSDictionary *)dict {
    return [[self alloc] initWithDictionary:dict];
}

+ (NSArray * _Nullable)objectsWithDicts:(NSArray<NSDictionary *> *)dicts {
    if (dicts.count == 0) DEBUG_RETURN(nil);
    
    NSMutableArray *array = NSMutableArray.array;
    
    for(NSDictionary *eachDictionary in dicts) {
        
        if(unlikely(![eachDictionary isKindOfClass:NSDictionary.class]))
            DEBUG_CONTINUE;
        
        id eachItem = [self objectWithDictionary:eachDictionary];
        
        DEBUG_ASSERT(eachItem != nil);
        
        [array hmd_addObject:eachItem];
    }
    
    DEBUG_ASSERT(array.count == dicts.count);
    
    return array.copy;
}

- (void)updateWithDictionary:(NSDictionary *)dict {
    
}

- (NSDictionary * _Nullable)postDict {
    DEBUG_RETURN(nil);
}

@end

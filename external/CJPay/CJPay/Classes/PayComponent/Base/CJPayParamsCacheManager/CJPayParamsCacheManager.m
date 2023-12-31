//
//  CJPayParamsCacheManager.m
//  CJPaySandBox
//
//  Created by 高航 on 2022/12/2.
//

#import "CJPayParamsCacheManager.h"
#import "CJPayParamsCacheService.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"

@interface CJPayParamsCacheManager()<CJPayParamsCacheService>

@property (nonatomic, strong) NSMutableDictionary *paramsCacheDict;

@end

@implementation CJPayParamsCacheManager


CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayParamsCacheService)
})

+ (instancetype)defaultService {
    static CJPayParamsCacheManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayParamsCacheManager new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.paramsCacheDict = [NSMutableDictionary new];
    }
    return self;
}

- (NSString *)i_getParamsFromCache:(NSString *)key {
    if (!Check_ValidString(key)) {
        return @"";
    } else {
        return [self.paramsCacheDict cj_stringValueForKey:key]?:@"";
    }
}

- (BOOL)i_setParams:(NSString *)params key:(NSString *)key {
    if (!Check_ValidString(key) || !(Check_ValidString(params))) {
        return NO;
    } else {
        [self.paramsCacheDict cj_setObject:params forKey:key];
        return YES;
    }
}

@end

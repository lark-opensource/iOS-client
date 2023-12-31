//
//  BDREExprCacheManager.m
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by bytedance on 2021/12/17.
//

#import "BDREExprCacheManager.h"
#import "BDREInstruction.h"
#import "BDRuleEngineSettings.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>

@interface BDREExprCacheManager ()

@property (nonatomic, strong) NSCache *exprCache;

@end

@implementation BDREExprCacheManager

+ (BDREExprCacheManager *)sharedManager
{
    static BDREExprCacheManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _exprCache = [[NSCache alloc] init];
    }
    return self;
}

- (void)addCache:(NSArray<BDRECommand *> *)commandStack forExpr:(NSString *)expr
{
    if (commandStack) {
        [self.exprCache setObject:commandStack forKey:expr];
    }
}

- (NSArray<BDRECommand *> *)findCacheForExpr:(NSString *)expr
{
    return [self.exprCache objectForKey:expr];
}

@end

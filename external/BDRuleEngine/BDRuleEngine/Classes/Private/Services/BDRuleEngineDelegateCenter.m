//
//  BDRuleEngineDelegateCenter.m
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/6/27.
//

#import "BDRuleEngineDelegateCenter.h"

@interface BDRuleEngineDelegateCenter()
@property (nonatomic, weak) id<BDRuleEngineDelegate> delegate;
@end
 
@implementation BDRuleEngineDelegateCenter

+ (BDRuleEngineDelegateCenter *)defaultCenter
{
    static BDRuleEngineDelegateCenter *center = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[BDRuleEngineDelegateCenter alloc] init];
    });
    return center;
}
 
+ (BOOL)setDelegate:(id<BDRuleEngineDelegate>)delegate
{
    if ([BDRuleEngineDelegateCenter defaultCenter].delegate) {
        return NO;
    }
    [BDRuleEngineDelegateCenter defaultCenter].delegate = delegate;
    return YES;
}
 
+ (id<BDRuleEngineDelegate>)delegate
{
    return [BDRuleEngineDelegateCenter defaultCenter].delegate;
}
 
@end

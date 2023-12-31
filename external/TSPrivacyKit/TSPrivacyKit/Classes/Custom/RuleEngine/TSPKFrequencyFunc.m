//
//  TSPKFrequencyFunc.m
//  Indexer
//
//  Created by admin on 2022/2/15.
//

#import "TSPKFrequencyFunc.h"
#import "TSPKUtils.h"
#import "TSPKLock.h"
#import "TSPKRuleEngineFrequencyManager.h"

@implementation TSPKFrequencyFunc

- (NSString *)symbol {
    return @"frequency";
}

// input {permission_type, api}

- (id)execute:(NSMutableArray *)params {
    NSString *name = params[0];
    
    return @([[TSPKRuleEngineFrequencyManager sharedManager] isVaildWithName:name]);
}

@end

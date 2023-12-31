//
//  TSPKHandleResult.m
//  Indexer
//
//  Created by admin on 2021/12/21.
//

#import "TSPKHandleResult.h"
#import "TSPKUtils.h"

NSString * const TSPKReturnValue = @"returnValue";

@implementation TSPKHandleResult

- (id)getObjectWithReturnType:(NSString *)returnType defaultValue:(id)defaultValue {
    if (self.returnValue == nil) {
        return defaultValue;
    }
    
    return [TSPKUtils createDefaultInstance:returnType defalutValue:self.returnValue];
}

@end

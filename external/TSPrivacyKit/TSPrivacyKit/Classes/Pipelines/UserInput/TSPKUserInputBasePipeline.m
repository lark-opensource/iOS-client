//
//  TSPKUserInputBasePipeline.m
//  Musically
//
//  Created by ByteDance on 2022/12/30.
//

#import "TSPKUserInputBasePipeline.h"
#import "TSPKConfigs.h"

@implementation TSPKUserInputBasePipeline

+ (TSPKHandleResult *_Nullable)handleAPIAccess:(NSString *_Nullable)api className:(NSString *_Nullable)className text:(NSString *_Nullable)text
{
    if (![[TSPKConfigs sharedConfig] enableGuardUserInput]) {
        return nil;
    }
    
    NSDictionary *params;
    if (text && ![text isEqualToString:@""]) {
        params = @{
            @"input" : text
        };
        
        return [self handleAPIAccess:api className:className params:params];
    }
    
    return nil;
}

+ (NSString *)dataType
{
    return TSPKDataTypeUserInput;
}

+ (BOOL)isEntryDefaultEnable
{
    return NO;
}

@end

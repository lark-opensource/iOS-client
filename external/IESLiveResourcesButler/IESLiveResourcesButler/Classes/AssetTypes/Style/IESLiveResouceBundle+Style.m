//
//  IESLiveResouceBundle+Style.m
//  Pods
//
//  Created by Zeus on 17/1/6.
//
//

#import "IESLiveResouceBundle+Style.h"
#import "IESLiveResouceStyleModel.h"

@implementation IESLiveResouceBundle (Style)

- (IESLiveResouceStyleModel * (^)(NSString *))style
{
    return ^(NSString *key) {
        return [self objectForKey:key type:@"style"];
    };
}

@end

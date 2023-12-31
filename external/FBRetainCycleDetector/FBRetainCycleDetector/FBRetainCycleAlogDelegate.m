//
//  FBRetainCycleAlogDelegate.m
//  FBRetainCycleDetector
//
//  Created by  郎明朗 on 2021/6/15.
//

#import "FBRetainCycleAlogDelegate.h"

@implementation FBRetainCycleAlogDelegate
+ (instancetype)sharedDelegate {
    static FBRetainCycleAlogDelegate *sharedDelegate= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDelegate = [[self alloc] init];
    });
    return sharedDelegate;
}
@end

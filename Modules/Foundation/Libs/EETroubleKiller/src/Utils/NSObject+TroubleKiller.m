//
//  NSObject+TroubleKiller.m
//  EETroubleKiller
//
//  Created by Meng on 2019/11/20.
//

#import "NSObject+TroubleKiller.h"

@implementation NSObject(TroubleKiller)

- (NSString *)tkClassName {
    return NSStringFromClass([self class]);
}

@end

//
//  STHookInfo.m
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "STHookInfo.h"
#import "STHookInfoPool.h"

@implementation STHookInfo

@synthesize selector = _selector;
@synthesize object = _object;
@synthesize options = _options;
@synthesize block = _block;

+ (instancetype)infoWithSelector:(SEL)selector object:(id)object options:(STOptions)options block:(id)block error:(NSError **)error {
    NSCParameterAssert(selector);
    NSCParameterAssert(block);
    
    STHookInfo *info = [[STHookInfo alloc] init];
    info.selector = selector;
    info.object = object;
    info.options = options;
    info.block = block;
    return info;
}

- (void)setOptions:(STOptions)options {
    _options = options;
    self->automaticRemoval = options & STOptionAutomaticRemoval;
}

- (BOOL)remove {
    id<STHookInfoPool> pool = st_getHookInfoPool(self.object, self.selector);
    return [pool removeInfo:self];
}

@end

//
//  TSDeallocAssociate.m
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/13.
//

#import "TSDeallocAssociate.h"

@interface TSDeallocAssociate()

@property (nonatomic, copy) TSDeallocBlock deallocBlock;

@end

@implementation TSDeallocAssociate

- (instancetype)initWithBlock:(TSDeallocBlock)block {
    if (self = [super init]) {
        _deallocBlock = [block copy];
    }
    return self;
}

- (void)dealloc {
    !_deallocBlock ?: _deallocBlock();
}

@end

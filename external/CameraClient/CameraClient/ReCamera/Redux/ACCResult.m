//
//  ACCResult.m
//  CameraClient
//
//  Created by liuqing on 2020/1/14.
//

#import "ACCResult.h"

@implementation ACCResult

+ (ACCResult *)success:(id)value
{
    return [[self alloc] initWithValue:value];
}

+ (ACCResult *)failure:(NSError *)error
{
    return [[self alloc] initWithError:error];
}

- (instancetype)initWithValue:(id)value
{
    self = [super init];
    
    if (self) {
        _value = value;
        _resultOneOfCase = ACCResult_OneOfCase_Success;
    }
    
    return self;
}

- (instancetype)initWithError:(NSError *)error
{
    self = [super init];
    
    if (self) {
        _error = error;
        _resultOneOfCase = ACCResult_OneOfCase_Failure;
    }
    
    return self;
}

- (ACCResult *)map:(id _Nullable (^)(id _Nullable))transform __attribute__((annotate("csa_ignore_block_use_check")))
{
    ACCResult *res = nil;
    
    switch (self.resultOneOfCase) {
        case ACCResult_OneOfCase_Success: {
            id value = self.value;
            if (transform) {
                value = transform(value);
            }
            res = [[self class] success:value];
            break;
        }
        case ACCResult_OneOfCase_Failure: {
            res = [[self class] failure:self.error];
            break;
        }
    }
    
    return res;
}

- (ACCResult *)flatMap:(ACCResult * _Nonnull (^)(id _Nullable))transform __attribute__((annotate("csa_ignore_block_use_check")))
{
    ACCResult *res = nil;
    
    switch (self.resultOneOfCase) {
        case ACCResult_OneOfCase_Success: {
            id value = self.value;
            if (transform) {
                res = transform(value);
            }
            if (!res) {
                res = [[self class] success:value];
            }
            break;
        }
        case ACCResult_OneOfCase_Failure: {
            res = [[self class] failure:self.error];
            break;
        }
    }
    
    return res;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[ACCResult class]]) {
        return NO;
    }

    return [self isEqualToResult:(ACCResult *)object];
}

- (BOOL)isEqualToResult:(ACCResult *)result
{
    if (!result) {
      return NO;
    }

    if (self.resultOneOfCase != result.resultOneOfCase) {
        return NO;
    }

    return [self.value isEqual:result.value];
}

@end

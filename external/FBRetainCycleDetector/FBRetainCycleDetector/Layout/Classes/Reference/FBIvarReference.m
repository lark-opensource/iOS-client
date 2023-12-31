/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBIvarReference.h"
#import "FBRetainCycleUtils.h"

@implementation FBIvarReference

- (instancetype)initWithIvar:(Ivar)ivar
{
  if (self = [super init]) {
    _name = @(ivar_getName(ivar));
    _type = [self _convertEncodingToType:ivar_getTypeEncoding(ivar)];
    _offset = ivar_getOffset(ivar);
    _index = _offset / sizeof(void *);
    _ivar = ivar;
  }

  return self;
}

- (FBType)_convertEncodingToType:(const char *)typeEncoding
{
  if (typeEncoding == NULL) {
    return FBUnknownType;
  }
  if (strlen(typeEncoding) < 1) {
    return FBUnknownType;
  }
  if (typeEncoding[0] == '{') {
    return FBStructType;
  }

  if (typeEncoding[0] == '@') {
    // It's an object or block

    // Let's try to determine if it's a block. Blocks tend to have
    // @? typeEncoding. Docs state that it's undefined type, so
    // we should still verify that ivar with that type is a block
    if (strncmp(typeEncoding, "@?", 2) == 0) {
      return FBBlockType;
    }

    return FBObjectType;
  }

  return FBUnknownType;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[%@, index: %lu]", _name, (unsigned long)_index];
}

#pragma mark - FBObjectReference

- (NSUInteger)indexInIvarLayout
{
  return _index;
}

- (id)objectReferenceFromObject:(id)object
{
    ptrdiff_t offset = ivar_getOffset(_ivar);
    void **idx = (void **)((uintptr_t)object + offset);
    if (!fb_safe_malloc_zone_from_ptr(*idx)) {//尝试解决 Crash
        return nil;
    }
    return object_getIvar(object, _ivar);
//    void *temp = (__bridge void *)(object_getIvar(object, _ivar));
//    if (!fb_safe_malloc_zone_from_ptr(temp)) {//尝试解决 Crash
//        return nil;
//    }
//    return (__bridge id)temp;
}

- (NSArray<NSString *> *)namePath
{
  return @[@(ivar_getName(_ivar))];
}

@end

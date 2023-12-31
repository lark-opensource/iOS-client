/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBObjectiveCGraphElement+Internal.h"
#import <malloc/malloc.h>

#import <objc/message.h>
#import <objc/runtime.h>

#import "FBAssociationManager.h"
#import "FBClassStrongLayout.h"
#import "FBObjectGraphConfiguration.h"
#import "FBRetainCycleUtils.h"
#import "FBRetainCycleDetector.h"

@implementation FBObjectiveCGraphElement

- (instancetype)initWithObject:(id)object
{
  return [self initWithObject:object
                configuration:[FBObjectGraphConfiguration new]];
}

- (instancetype)initWithObject:(id)object
                 configuration:(nonnull FBObjectGraphConfiguration *)configuration
{
  return [self initWithObject:object
                configuration:configuration
                     namePath:nil];
}

- (instancetype)initWithObject:(id)object
                 configuration:(nonnull FBObjectGraphConfiguration *)configuration
                      namePath:(NSArray<NSString *> *)namePath
{
  if (self = [super init]) {
#if _INTERNAL_RCD_ENABLED
    // xushuangqing 有些私有对象，比如 _PFResultASCIIString，在被 weak 持有时会 crash，这些对象并不是 malloc 出来的，所以用 malloc_zone_from_ptr 过滤掉这些对象 https://bytedance.feishu.cn/docs/doccnHPW3RI8hlDwaR7SmXvQoWe
    malloc_zone_t *zone = fb_safe_malloc_zone_from_ptr((__bridge void *)object);
    if (zone) {
      Class aCls = object_getClass(object);
      // We are trying to mimic how ObjectiveC does storeWeak to not fall into
      // _objc_fatal path
      // https://github.com/bavarious/objc4/blob/3f282b8dbc0d1e501f97e4ed547a4a99cb3ac10b/runtime/objc-weak.mm#L369
      BOOL (*allowsWeakReference)(id, SEL) =
      (__typeof__(allowsWeakReference))class_getMethodImplementation(aCls, @selector(allowsWeakReference));
      if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
        if (allowsWeakReference(object, @selector(allowsWeakReference))) {
          // This is still racey since allowsWeakReference could change it value by now.
          _object = object;
        }
      } else {
        _object = object;
      }
    }
#endif
    _namePath = namePath;
    _configuration = configuration;
  }

  return self;
}

- (NSSet *)allRetainedObjects
{
  NSArray *retainedObjectsNotWrapped = [FBAssociationManager associationsForObject:_object];
  NSMutableSet *retainedObjects = [NSMutableSet new];

  for (id obj in retainedObjectsNotWrapped) {
    FBObjectiveCGraphElement *element = FBWrapObjectGraphElementWithContext(self,
                                                                            obj,
                                                                            _configuration,
                                                                            @[@"__associated_object"]);
    if (element) {
      [retainedObjects addObject:element];
    }
  }

  return retainedObjects;
}

- (BOOL)isEqual:(id)object
{
  if ([object isKindOfClass:[FBObjectiveCGraphElement class]]) {
    FBObjectiveCGraphElement *objcObject = object;
    // Use pointer equality
    return objcObject.object == _object;
  }
  return NO;
}

- (NSUInteger)hash
{
  return (size_t)_object;
}

- (NSString *)description
{
  if (_namePath) {
    NSString *namePathStringified = [_namePath componentsJoinedByString:@" -> "];
    return [NSString stringWithFormat:@"-> %@ -> %@ ", namePathStringified, [self classNameOrNull]];
  }
  return [NSString stringWithFormat:@"-> %@ ", [self classNameOrNull]];
}

- (size_t)objectAddress
{
  return (size_t)_object;
}

- (NSString *)classNameOrNull
{
  NSString *className = NSStringFromClass([self objectClass]);
  if (!className) {
    className = @"(null)";
  }

  return className;
}

- (Class)objectClass
{
  return object_getClass(_object);
}

-(id)object{
    //增加保护：访问 _object 属性之前，先判断是否是一个合法的heap地址
    static ptrdiff_t offset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unsigned int count;
        Class aCls = [FBObjectiveCGraphElement class];
        Ivar *ivars = class_copyIvarList(aCls, &count);
        for (unsigned int i = 0; i < count; ++i) {
            NSString *temp = @(ivar_getName(ivars[i]));
            if ([temp isEqual:@"_object"]) {
                offset = ivar_getOffset(ivars[i]);
            }
        }
        free(ivars);
    });
    void **idx = (void **)((uintptr_t)self + offset);
    if (!fb_safe_malloc_zone_from_ptr(*idx)) {//尝试解决 Crash
        return nil;
    }
    return _object;
}

@end

/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRetainCycleUtils.h"

#import <objc/runtime.h>

#import "FBBlockStrongLayout.h"
#import "FBClassStrongLayout.h"
#import "FBObjectiveCBlock.h"
#import "FBObjectiveCGraphElement.h"
#import "FBObjectiveCNSCFTimer.h"
#import "FBObjectiveCObject.h"
#import "FBObjectGraphConfiguration.h"
#import "FBSwiftGraphElement.h"

extern malloc_zone_t *malloc_zone_from_ptr(const void *ptr);

static BOOL _ShouldBreakGraphEdge(FBObjectGraphConfiguration *configuration,
                                  FBObjectiveCGraphElement *fromObject,
                                  NSString *byIvar,
                                  Class toObjectOfClass) {
  for (FBGraphEdgeFilterBlock filterBlock in configuration.filterBlocks) {
    if (filterBlock(fromObject, byIvar, toObjectOfClass) == FBGraphEdgeInvalid) {
      return YES;
    }
  }

  return NO;
}


FBObjectiveCGraphElement *FBWrapObjectGraphElementWithContext(FBObjectiveCGraphElement *sourceElement,
                                                              id object,
                                                              FBObjectGraphConfiguration *configuration,
                                                              NSArray<NSString *> *namePath) {
    if (_ShouldBreakGraphEdge(configuration, sourceElement, [namePath firstObject], object_getClass(object))) {//过滤白名单中的持有关系
        return nil;
        
    }
    
    FBObjectiveCGraphElement *newElement;
    
    if ([[FBSwiftGraphElement class] judegeIfSwiftInstanceWith:object]) {
        newElement = [[FBSwiftGraphElement alloc] initWithObject:object
                                                 configuration:configuration
                                                      namePath:namePath];
    } else {
        if (FBObjectIsBlock((__bridge void *)object)) {
          newElement = [[FBObjectiveCBlock alloc] initWithObject:object
                                                   configuration:configuration
                                                        namePath:namePath];
        } else {
          if ([object_getClass(object) isSubclassOfClass:[NSTimer class]] &&
              configuration.shouldInspectTimers) {
            newElement = [[FBObjectiveCNSCFTimer alloc] initWithObject:object
                                                         configuration:configuration
                                                              namePath:namePath];
          } else {
            newElement = [[FBObjectiveCObject alloc] initWithObject:object
                                                      configuration:configuration
                                                           namePath:namePath];
          }
        }
    }
    
  return (configuration && configuration.transformerBlock) ? configuration.transformerBlock(newElement) : newElement;
}

FBObjectiveCGraphElement *FBWrapObjectGraphElement(FBObjectiveCGraphElement *sourceElement,
                                                   id object,
                                                   FBObjectGraphConfiguration *configuration) {
  return FBWrapObjectGraphElementWithContext(sourceElement, object, configuration, nil);
}

malloc_zone_t *fb_safe_malloc_zone_from_ptr(const void *ptr) {
    if (@available(iOS 16.0, *)) {
        if ((uint64_t)ptr == 0xffffffffffffffff) {
            return nil;
        }
    }
    return malloc_zone_from_ptr(ptr);
}

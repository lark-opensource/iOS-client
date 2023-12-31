/**
 * Copyright (c) 2016-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <stack>
#import <unordered_map>
#import <unordered_set>

#import "FBNodeEnumerator.h"
#import "FBObjectiveCGraphElement.h"
#import "FBObjectiveCObject.h"
#import "FBRetainCycleDetector+Internal.h"
#import "FBRetainCycleUtils.h"
#import "FBStandardGraphEdgeFilters.h"

#ifdef FBRetainCycleDetector_POD_VERSION
NSString * const FBRetainCycleDetectorVersion = FBRetainCycleDetector_POD_VERSION;
#else
NSString * const FBRetainCycleDetectorVersion = @"13_0.1.5-alpha.3";
#endif

static const NSUInteger kFBRetainCycleDetectorDefaultStackDepth = 15;
static const NSUInteger kFBRetainCycleDetectorDefaultMaxTraversedNodeNumber = 5000;
static const NSUInteger kFBRetainCycleDetectorDefaultMaxCycleNumber = 5;

@implementation FBRetainCycleDetector
{
  NSMutableArray *_candidates;
  FBObjectGraphConfiguration *_configuration;
  NSMutableSet *_objectSet;
}

- (instancetype)initWithConfiguration:(FBObjectGraphConfiguration *)configuration
{
  if (self = [super init]) {
    _configuration = configuration;
    _candidates = [NSMutableArray new];
    _objectSet = [NSMutableSet new];
  }

  return self;
}

- (instancetype)init
{
  return [self initWithConfiguration:
          [[FBObjectGraphConfiguration alloc] initWithFilterBlocks:FBGetStandardGraphEdgeFilters()
                                               shouldInspectTimers:YES]];
}

- (void)addCandidate:(id)candidate
{
  FBObjectiveCGraphElement *graphElement = FBWrapObjectGraphElement(nil, candidate, _configuration);
  if (graphElement) {
    [_candidates addObject:graphElement];
  }
}

- (NSSet<NSArray<FBObjectiveCGraphElement *> *> *)findRetainCycles
{
  return [self findRetainCyclesWithMaxCycleLength:kFBRetainCycleDetectorDefaultStackDepth maxTraversedNodeNumber:kFBRetainCycleDetectorDefaultMaxTraversedNodeNumber maxCycleNum:kFBRetainCycleDetectorDefaultMaxCycleNumber];
}

- (NSSet<NSArray<FBObjectiveCGraphElement *> *> *)findRetainCyclesWithMaxCycleLength:(NSUInteger)length  maxTraversedNodeNumber:(NSUInteger)nodeNumber maxCycleNum:(NSUInteger)maxCycleNum
{
  NSMutableSet<NSArray<FBObjectiveCGraphElement *> *> *allRetainCycles = [NSMutableSet new];
  for (FBObjectiveCGraphElement *graphElement in _candidates) {
    NSSet<NSArray<FBObjectiveCGraphElement *> *> *retainCycles = [self _findRetainCyclesInObject:graphElement
                                                                                      stackDepth:length
                                                                          maxTraversedNodeNumber:nodeNumber
                                                                                     maxCycleNum:maxCycleNum];
    [allRetainCycles unionSet:retainCycles];
  }
  [_candidates removeAllObjects];
  [_objectSet removeAllObjects];

  // Filter cycles that have been broken down since we found them.
  // These are false-positive that were picked-up and are transient cycles.
  NSMutableSet<NSArray<FBObjectiveCGraphElement *> *> *brokenCycles = [NSMutableSet set];
  for (NSArray<FBObjectiveCGraphElement *> *itemCycle in allRetainCycles) {
    for (FBObjectiveCGraphElement *element in itemCycle) {
      if (element.object == nil) {
        // At least one element of the cycle has been removed, thus breaking the cycle.
        [brokenCycles addObject:itemCycle];
        break;
      }
    }
  }
  [allRetainCycles minusSet:brokenCycles];

  return allRetainCycles;
}

- (NSSet<NSArray<FBObjectiveCGraphElement *> *> *)_findRetainCyclesInObject:(FBObjectiveCGraphElement *)graphElement
                                                                 stackDepth:(NSUInteger)stackDepth
                                                     maxTraversedNodeNumber:(NSUInteger)maxNodeNumber
                                                                maxCycleNum:(NSUInteger)maxCycleNum
{
  NSMutableSet<NSArray<FBObjectiveCGraphElement *> *> *retainCycles = [NSMutableSet new];
  FBNodeEnumerator *wrappedObject = [[FBNodeEnumerator alloc] initWithObject:graphElement];

  // We will be doing DFS over graph of objects

  // Stack will keep current path in the graph
  NSMutableArray<FBNodeEnumerator *> *stack = [NSMutableArray new];

  // To make the search non-linear we will also keep a set of previously visited nodes.
  NSMutableSet<FBNodeEnumerator *> *objectsOnPath = [NSMutableSet new];

  // Let's start with the root
  [stack addObject:wrappedObject];
    
  NSMutableDictionary<NSString *, NSNumber *> *enumeratedClasses = [[NSMutableDictionary alloc] init];

  while ([stack count] > 0 && [_objectSet count] < maxNodeNumber) {
    // Algorithm creates many short-living objects. It can contribute to few
    // hundred megabytes memory jumps if not handled correctly, therefore
    // we're gonna drain the objects with our autoreleasepool.
    @autoreleasepool {
      // Take topmost node in stack and mark it as visited
      FBNodeEnumerator *top = [stack lastObject];

      // We don't want to retraverse the same subtree.
      if (![objectsOnPath containsObject:top]) {
        if ([_objectSet containsObject:@([top.object objectAddress])]) {
          [stack removeLastObject];
          continue; //eg A->B、A->C && B->D、C->D && D->E->F,avoid retraverse D tree twice
        }
        // Add the object address to the set as an NSNumber to avoid unnecessarily retaining the object
        [_objectSet addObject:@([top.object objectAddress])];
      }

      [objectsOnPath addObject:top];

      // Take next adjecent node to that child. Wrapper object can
      // persist iteration state. If we see that node again, it will
      // give us new adjacent node unless it runs out of them
      FBNodeEnumerator *firstAdjacent = [top nextObject];
      if (firstAdjacent) {
        // Current node still has some adjacent not-visited nodes

        BOOL shouldPushToStack = NO;

        // Check if child was already seen in that path
        // ⚠️ firstAdjacent is type FBNodeEnumerator,which overvide function isEqual. So this is not based on the address of firstAdjacent itself to determine whether it is equal
        if ([objectsOnPath containsObject:firstAdjacent]) {
          // We have caught a retain cycle

          // Ignore the first element which is equal to firstAdjacent, use firstAdjacent
          // we're doing that because firstAdjacent has set all contexts, while its
          // first occurence could be a root without any context
          NSUInteger index = [stack indexOfObject:firstAdjacent];
          NSInteger length = [stack count] - index;

          if (index == NSNotFound) {
            // Object got deallocated between checking if it exists and grabbing its index
            shouldPushToStack = YES;
          } else {
            
            // extract Cycle
            NSRange cycleRange = NSMakeRange(index, length);
            NSMutableArray<FBNodeEnumerator *> *cycle = [[stack subarrayWithRange:cycleRange] mutableCopy];
            [cycle replaceObjectAtIndex:0 withObject:firstAdjacent];

            // 1. Unwrap the cycle
            // 2. Shift to lowest address (if we omit that, and the cycle is created by same class,
            //    we might have duplicates) ——Sort by address
            // 3. Shift by class (lexicographically)——Sort by class name
            [retainCycles addObject:[self _shiftToUnifiedCycle:[self _unwrapCycle:cycle]]];
            if (retainCycles.count > maxCycleNum) {
                [stack removeAllObjects];
                return  retainCycles;
            }
          }
        } else {
          // Node is clear to check, add it to stack and continue
          shouldPushToStack = YES;
        }
        
        if (shouldPushToStack && [firstAdjacent.object.object isProxy]) {
            shouldPushToStack = NO;
        }
        
        NSInteger classEnumeratedCount = 0;
        if (shouldPushToStack) {
            classEnumeratedCount = [[enumeratedClasses objectForKey:[firstAdjacent.object classNameOrNull]] integerValue];
            if (classEnumeratedCount > maxCycleNum) {
                shouldPushToStack = NO;
            }
        }


        if (shouldPushToStack) {
          [enumeratedClasses setObject:@(classEnumeratedCount+1) forKey:[firstAdjacent.object classNameOrNull]];
          if ([stack count] < stackDepth) {
            [stack addObject:firstAdjacent];
          }
        }
      } else {
        // Node has no more adjacent nodes, it itself is done, move on
        [stack removeLastObject];
        [objectsOnPath removeObject:top];
      }
    }
  }
  return retainCycles;
}

// Turn all enumerators into object graph elements
- (NSArray<FBObjectiveCGraphElement *> *)_unwrapCycle:(NSArray<FBNodeEnumerator *> *)cycle
{
  NSMutableArray *unwrappedArray = [NSMutableArray new];
  for (FBNodeEnumerator *wrapped in cycle) {
    [unwrappedArray addObject:wrapped.object];
  }

  return unwrappedArray;
}

// We do that so two cycles can be recognized as duplicates
- (NSArray<FBObjectiveCGraphElement *> *)_shiftToUnifiedCycle:(NSArray<FBObjectiveCGraphElement *> *)array
{
  return [self _shiftToLowestLexicographically:[self _shiftBufferToLowestAddress:array]];
}

- (NSArray<NSString *> *)_extractClassNamesFromGraphObjects:(NSArray<FBObjectiveCGraphElement *> *)array
{
  NSMutableArray *arrayOfClassNames = [NSMutableArray new];

  for (FBObjectiveCGraphElement *obj in array) {
    [arrayOfClassNames addObject:[obj classNameOrNull]];
  }

  return arrayOfClassNames;
}

/**
 The problem this circular shift solves is when we have few retain cycles for different runs that
 are technically the same cycle shifted. Object instances are different so if objects A and B
 create cycle, but on one run the address of A is lower than B, and on second B is lower than A,
 we will get a duplicate we have to get rid off.

 For that not to happen we use the circular shift that is smallest lexicographically when
 looking at class names.

 The version of this algorithm is pretty inefficient. It just compares given shifts and
 tries to find the smallest one. Doing something faster here is premature optimisation though
 since the retain cycles are usually arrays of length not bigger than 10 and there is not a lot
 of them (like 100 per run tops).

 If that ever occurs to be a problem for future reference use lexicographically minimal
 string rotation algorithm variation.
 */
- (NSArray<FBObjectiveCGraphElement *> *)_shiftToLowestLexicographically:(NSArray<FBObjectiveCGraphElement *> *)array
{
  NSArray<NSString *> *arrayOfClassNames = [self _extractClassNamesFromGraphObjects:array];

  NSArray<NSString *> *copiedArray = [arrayOfClassNames arrayByAddingObjectsFromArray:arrayOfClassNames];
  NSUInteger originalLength = [arrayOfClassNames count];

  NSArray *currentMinimalArray = arrayOfClassNames;
  NSUInteger minimumIndex = 0;

  for (NSUInteger i = 0; i < originalLength; ++i) {
    NSArray<NSString *> *nextSubarray = [copiedArray subarrayWithRange:NSMakeRange(i, originalLength)];
    if ([self _compareStringArray:currentMinimalArray
                        withArray:nextSubarray] == NSOrderedDescending) {
      currentMinimalArray = nextSubarray;
      minimumIndex = i;
    }
  }

  NSRange minimumArrayRange = NSMakeRange(minimumIndex,
                                          [array count] - minimumIndex);
  NSMutableArray<FBObjectiveCGraphElement *> *minimumArray = [[array subarrayWithRange:minimumArrayRange] mutableCopy];
  [minimumArray addObjectsFromArray:[array subarrayWithRange:NSMakeRange(0, minimumIndex)]];
  return minimumArray;
}

- (NSComparisonResult)_compareStringArray:(NSArray<NSString *> *)a1
                                withArray:(NSArray<NSString *> *)a2
{
  // a1 and a2 should be the same length
  for (NSUInteger i = 0; i < [a1 count]; ++i) {
    NSString *s1 = a1[i];
    NSString *s2 = a2[i];

    NSComparisonResult comparision = [s1 compare:s2];
    if (comparision != NSOrderedSame) {
      return comparision;
    }
  }

  return NSOrderedSame;
}

// Sort by address of object in FBObjectiveCGraphElement
- (NSArray<FBObjectiveCGraphElement *> *)_shiftBufferToLowestAddress:(NSArray<FBObjectiveCGraphElement *> *)cycle
{
  NSUInteger idx = 0, lowestAddressIndex = 0;
  size_t lowestAddress = NSUIntegerMax;
  for (FBObjectiveCGraphElement *obj in cycle) {
    if ([obj objectAddress] < lowestAddress) {
      lowestAddress = [obj objectAddress];
      lowestAddressIndex = idx;
    }

    idx++;
  }

  if (lowestAddressIndex == 0) {
    return cycle;
  }

  NSRange cycleRange = NSMakeRange(lowestAddressIndex, [cycle count] - lowestAddressIndex);
  NSMutableArray<FBObjectiveCGraphElement *> *array = [[cycle subarrayWithRange:cycleRange] mutableCopy];
  [array addObjectsFromArray:[cycle subarrayWithRange:NSMakeRange(0, lowestAddressIndex)]];
  return array;
}

@end

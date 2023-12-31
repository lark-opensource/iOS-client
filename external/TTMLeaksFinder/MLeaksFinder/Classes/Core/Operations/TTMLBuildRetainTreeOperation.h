/**
 * Tencent is pleased to support the open source community by making MLeaksFinder available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company. All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 *
 * https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import "TTMLeaksFinder.h"
#import "TTMLNodeEnumerator.h"

typedef void(^TTMLBuildRetainTreeCompletionBlock)(TTMLGraphNode *rootNode);

@interface TTMLBuildRetainTreeOperation : NSOperation

@property (atomic, strong, readonly) id rootObject;
@property (atomic, assign, readonly) size_t rootAddress;
@property (atomic, strong, readonly) TTMLGraphNode *rootNode; //rootNode is nil until operation finished

- (id)initWithRootObject:(id)rootObject
    needNormalRetainTree:(BOOL)needNormalRetainTree
       graphConfiguraion:(FBObjectGraphConfiguration *)graphConfiguration
              stackDepth:(NSInteger)stackDepth
         completionBlock:(TTMLBuildRetainTreeCompletionBlock)completionBlock;

- (void)addCompletionBlock:(TTMLBuildRetainTreeCompletionBlock)completionBlock;

@end

//
//  NlEBranch+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/7.
//

#ifndef NlEBranch_iOS_h
#define NlEBranch_iOS_h

#import <Foundation/Foundation.h>
#import "NLECommit+iOS.h"

NS_ASSUME_NONNULL_BEGIN


@protocol NLEBranchDelegate <NSObject>

- (void)branchDidChange;

@end

@interface NLEBranch_OC : NSObject
//              head
//        redo <-↓-> undo
// front - [] [] [] [] [] [] - back

- (void)clear;

- (void)addCommit:(NLECommit_OC *)commit;

- (NLECommit_OC*) getHead;      // HEAD
- (NLECommit_OC*) getHeadPrev;  // HEAD-1
- (NLECommit_OC*) getHeadNext;  // HEAD+1

- (NLECommit_OC*) resetToPrev;  // HEAD -> HEAD-1; return new HEAD
- (NLECommit_OC*) resetToNext;  // HEAD -> HEAD+1; return new HEAD

- (void)addListener:(id<NLEBranchDelegate>)listener;
- (void)removeListener:(id<NLEBranchDelegate>)listener;

@end

NS_ASSUME_NONNULL_END

#endif /* NlEBranch_iOS_h */

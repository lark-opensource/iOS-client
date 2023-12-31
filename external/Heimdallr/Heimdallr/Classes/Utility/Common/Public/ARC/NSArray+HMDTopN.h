//
//  NSArray+HMDTopN.h
//  Pods
//
//  Created by zhangxiao on 2021/4/25.
//

#import <Foundation/Foundation.h>

@interface NSArray (HMDTopN)

+ (NSArray * _Nullable)hmd_heapTopNWithArray:(NSArray *_Nullable)array topN:(NSUInteger)topN usingComparator:(NSComparator NS_NOESCAPE _Nullable)cmptr;

@end

@interface NSMutableArray (HMDTopN)

@property (nonatomic, assign) NSUInteger hmd_topN;

/// must init before call hmd_heapTopNAddObject:
@property (nonatomic, copy, nullable) NSComparator hmd_cmptr;

- (void)hmd_heapTopNAddObject:(id _Nullable)object;
- (NSArray *_Nullable)hmd_topNArray;

@end

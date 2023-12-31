//
//  BDPSTLQueue.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/23.
//

#import <Foundation/Foundation.h>

@interface BDPSTLQueue : NSObject

- (void)enqueue:(id _Nullable)object;
- (id _Nonnull )dequeue;
- (void)clear;
- (BOOL)empty;
- (void)enumerateObjectsUsingBlock:(void (^_Nullable)(id _Nonnull object, BOOL * _Nonnull stop))block;

@end

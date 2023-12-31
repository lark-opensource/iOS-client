//
//  OPSTLQueue.h
//  TTMicroApp
//
//  Created by yi on 2021/12/23.
//

#import <Foundation/Foundation.h>

@interface OPSTLQueue : NSObject

- (void)enqueue:(id _Nullable)object;
- (id _Nonnull )dequeue;
- (void)clear;
- (BOOL)empty;
- (void)enumerateObjectsUsingBlock:(void (^_Nullable)(id _Nonnull object, BOOL * _Nonnull stop))block;

@end

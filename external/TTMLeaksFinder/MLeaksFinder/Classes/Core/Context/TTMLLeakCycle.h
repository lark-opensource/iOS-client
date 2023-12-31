//
//  TTMLLeakCycle.h
//  TTMLeaksFinder
//
//  Created by maruipu on 2020/11/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FBObjectiveCGraphElement;
@class TTMLLeakCycleNode;

@interface TTMLLeakCycle : NSObject

@property (nonatomic, strong) NSArray<TTMLLeakCycleNode *> *nodes;
@property (nonatomic, strong) NSString *retainCycle;
@property (nonatomic, strong) NSString *keyClassName;
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSString *leakSize;
@end

@protocol TTMLLeakCycleNodeInterpreter <NSObject>

- (void)interpretCycleNode:(TTMLLeakCycleNode *)node withObject:(id)object;

@end

@interface TTMLLeakCycleNode : NSObject

@property (nonatomic, assign, readonly) BOOL isBlock;
@property (nonatomic, assign, readonly) NSUInteger index;
@property (nonatomic, copy, readonly) NSArray<NSString *> *path;
@property (nonatomic, copy, readonly) NSString *className;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSString *, id> *extra;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (void)registerInterpreter:(NSArray<id<TTMLLeakCycleNodeInterpreter>> *)interpreters;
+ (void)removeAllInterpreters;

+ (instancetype)cycleNodeWithElement:(FBObjectiveCGraphElement *)element index:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

//
//  TTNodeEnumerator.h
//  MLeaksFinder
//
//  Created by renpengcheng on 2019/2/20.
//  Copyright © 2019 zeposhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FBObjectiveCGraphElement;
@protocol TTMLNodeAddChildrenDelegate;

@interface TTMLGraphNode : NSObject

@property (nonatomic, weak) id object;//检测类型对象
@property (nonatomic, strong) NSString *clazzName;
@property (nonatomic, weak) TTMLGraphNode *parent;
@property (nonatomic, strong) NSMutableArray<TTMLGraphNode *> *children;

//Debug用
- (NSString *)treeDescription;

- (instancetype)initWithObject:(id)object;
- (NSInteger)traverseAndCountClassName:(NSString *)className shouldCount:(BOOL)shouldCount;

@end


@interface TTMLNodeEnumerator : NSEnumerator

@property (nonatomic, strong) TTMLGraphNode *node;
@property (nonatomic, weak) id<TTMLNodeAddChildrenDelegate> delegate;
@property (nonatomic, strong, readonly, nonnull) FBObjectiveCGraphElement *object;
/**
 Designated initializer
 */
- (nonnull instancetype)initWithObject:(nonnull FBObjectiveCGraphElement *)object;
- (nonnull instancetype)initWithObject:(FBObjectiveCGraphElement *)object addChildDelegate:(id<TTMLNodeAddChildrenDelegate>)delegate;

- (nullable TTMLNodeEnumerator *)nextObject;



@end

@protocol TTMLNodeAddChildrenDelegate <NSObject>

- (NSSet *)addedChildrenForNodeEnumerator:(TTMLNodeEnumerator *)nodeEnumerator;

@end

NS_ASSUME_NONNULL_END

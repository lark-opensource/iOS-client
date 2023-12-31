//
//  BDREGraphNode.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import <Foundation/Foundation.h>

#import "BDREGraphFootPrint.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREGraphNode : NSObject

@property (nonatomic, strong, readonly) NSArray<BDREGraphNode *> *pointNodes;
@property (nonatomic, assign, readonly) NSUInteger minIndex;
@property (nonatomic, assign, readonly) BOOL isEndNode;

- (void)addPointNode:(BDREGraphNode *)node;
- (void)updateMinIndex:(NSUInteger)index;

- (void)travelWithFootPrint:(BDREGraphFootPrint *)graphFootPrint;
- (BOOL)canPassWithFootPrint:(BDREGraphFootPrint *)graphFootPrint;
- (void)visitWithFootPrint:(BDREGraphFootPrint *)graphFootPrint previousNode:(BDREGraphNode *)previousNode;
- (BOOL)isVisitedWithFootPrint:(BDREGraphFootPrint *)graphFootPrint;

- (id)valueWithFootPrint:(BDREGraphFootPrint *)graphFootPrint;
- (NSString *)identifier;

@end

NS_ASSUME_NONNULL_END

//
//  BDREAndGraphNode.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/18.
//

#import "BDREGraphNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREAndDelegateGraphNode : BDREGraphNode
@end

@interface BDREAndGraphNode : BDREGraphNode

@property (nonatomic, strong, readonly) BDREAndDelegateGraphNode *leftDelegateNode;
@property (nonatomic, strong, readonly) BDREAndDelegateGraphNode *rightDelegateNode;

@end

NS_ASSUME_NONNULL_END

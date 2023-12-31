//
//  BDPCascadeStyleNode.h
//  Timor
//
//  Created by 刘相鑫 on 2019/10/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPCascadeStyleNode : NSObject

@property (nonatomic, weak) BDPCascadeStyleNode *parentNode;
@property (nonatomic, strong) NSMutableArray<BDPCascadeStyleNode *> *childNodes;
@property (nonatomic, copy) NSString *category;

@property (nonatomic, strong) Class cls;

- (void)addChildNode:(BDPCascadeStyleNode *)node;
- (void)removeFromParentNode;
- (void)applyStyleForObject:(id)sender;

@end

NS_ASSUME_NONNULL_END

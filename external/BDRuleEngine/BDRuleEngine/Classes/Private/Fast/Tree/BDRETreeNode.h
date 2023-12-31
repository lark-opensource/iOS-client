//
//  BDRETreeNode.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/12.
//

#import <Foundation/Foundation.h>

@class BDRECommand;

NS_ASSUME_NONNULL_BEGIN

@interface BDRETreeNode : NSObject

@property (nonatomic, strong, readonly) BDRECommand *command;
@property (nonatomic, strong, nullable, readonly) NSArray<BDRETreeNode *> *children;

- (instancetype)initWithCommand:(BDRECommand *)command children:(nullable NSArray<BDRETreeNode *> *)children;

@end

NS_ASSUME_NONNULL_END

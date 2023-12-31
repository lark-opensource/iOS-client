//
//  BDREEntryGraphNode.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import <Foundation/Foundation.h>

#import "BDREGraphNode.h"
#import "BDREConstGraphNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREEntryGraphNode : BDREGraphNode

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, assign) BOOL isRegisterParam;
@property (nonatomic, assign) BOOL isCollection;

- (instancetype)initWithIdentifier:(NSString *)identifier;
- (void)connectToConstNode:(BDREConstGraphNode *)constNode;

@end

NS_ASSUME_NONNULL_END

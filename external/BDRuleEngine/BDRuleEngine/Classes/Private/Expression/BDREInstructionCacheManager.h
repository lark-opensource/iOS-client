//
//  BDREInstructionCacheManager.h
//  Aweme
//
//  Created by Chengmin Zhang on 2022/8/29.
//

#import <Foundation/Foundation.h>
#import "BDRECommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREInstructionCacheManager : NSObject

@property (nonatomic, copy, readonly) NSString *signature;

+ (nonnull BDREInstructionCacheManager *)sharedManager;

- (void)updateInstructionJsonMap:(nonnull NSDictionary *)instructionMap signature:(nonnull NSString *)signature;

- (nullable NSArray<BDRECommand *> *)findCommandsForExpr:(nonnull NSString *)expr;

@end

NS_ASSUME_NONNULL_END

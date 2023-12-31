//
//  BDREBaseNode.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "BDRuleEngineLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREBaseNode : NSObject

@property (nonatomic, strong) NSString *aOriginValue;
@property (nonatomic, assign) NSUInteger wordIndex;
@property (nonatomic, assign) NSUInteger priority;

- (instancetype)initAsBaseNode:(NSString *)originValue index:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

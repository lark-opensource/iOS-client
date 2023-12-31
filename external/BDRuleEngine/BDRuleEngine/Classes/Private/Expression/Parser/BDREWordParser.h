//
//  BDREWordParser.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "BDREOperatorManager.h"
#import "BDREFuncManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREWord : NSObject

@property (nonatomic, strong) NSString *wordStr;
@property (nonatomic, assign) NSUInteger line;
@property (nonatomic, assign) NSUInteger col;

- (instancetype)initWordWithStr:(NSString *)wordStr line:(NSUInteger)line col:(NSUInteger)col;

@end

@interface BDREWordParser : NSObject

+ (nullable NSArray *)splitWord:(NSString *)expr error:(NSError **)error;

+ (nullable NSArray *)parseWordToNode:(NSArray *)words error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

//
//  LKREWordParser.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "LKREOperatorManager.h"
#import "LKREFuncManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREWord : NSObject

@property (nonatomic, strong) NSString *wordStr;
@property (nonatomic, assign) NSUInteger line;
@property (nonatomic, assign) NSUInteger col;

- (LKREWord *)initWordWithStr:(NSString *)wordStr line:(NSUInteger)line col:(NSUInteger)col;

@end

@interface LKREWordParser : NSObject

- (NSArray *)splitWord:(NSString *)expr error:(NSError **)error;

- (NSArray *)parseWordToNode:(NSArray *)words error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

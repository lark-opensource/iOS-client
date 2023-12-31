//
//  LKREExprParser.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKREExprParser : NSObject

- (NSArray *)parse:(NSString *)expr error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

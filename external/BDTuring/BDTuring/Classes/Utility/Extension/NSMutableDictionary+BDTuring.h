//
//  NSMutableDictionary+BDTuring.h
//  BDTuring
//
//  Created by bob on 2020/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (BDTuring)

/*
 the struct should be the same
 e.g.
 {"x":"xx"} defaultMerge {"x":"xxx","y","yyy"}
 ==> {"x":"xx","y","yyy"}
 
 {"x":"xx"} overrideMerge {"x":"xxx","y","yyy"}
 ==> {"x":"xxx","y","yyy"}
 
 */
- (void)turing_defaultMerge:(NSDictionary *)value;
- (void)turing_overrideMerge:(NSDictionary *)value;

- (void)addContentWithKey:(NSString *)key fromDic:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END

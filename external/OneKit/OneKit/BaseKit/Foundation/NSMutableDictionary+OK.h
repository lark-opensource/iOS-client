//
//  NSMutableDictionary+OK.h
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (OK)

- (void)ok_setObject:(nullable id)anObject forKey:(nullable id<NSCopying>)aKey;

/*
the struct should be the same
e.g.
{"x":"xx"} skipMerge {"x":"xxx","y","yyy"}
==> {"x":"xx","y","yyy"}

{"x":"xx"} overrideMerge {"x":"xxx","y","yyy"}
==> {"x":"xxx","y","yyy"}

*/
- (void)ok_skipMerge:(NSDictionary *)value;
- (void)ok_overrideMerge:(NSDictionary *)value;

@end

NS_ASSUME_NONNULL_END

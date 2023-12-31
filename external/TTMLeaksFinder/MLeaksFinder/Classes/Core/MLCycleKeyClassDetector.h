//
//  MLCycleKeyClassDetector.h
//  Pods
//
//  Created by xushuangqing on 2020/2/24.
//

#import <Foundation/Foundation.h>

typedef struct {
    u_int64_t index; // key class 在 retainCycle 中的下标
    NSString * _Nullable keyClassName; 
}cyle_key_class;

NS_ASSUME_NONNULL_BEGIN

@interface MLCycleKeyClassDetector : NSObject

+ (cyle_key_class)keyClassNameForRetainCycle:(NSArray *)retainCycle;

@end

NS_ASSUME_NONNULL_END

//
//  BDXLazyLoadProxy.h
//  BulletX
//
//  Created by bytedance on 2021/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXLazyLoadProxy<__covariant ObjectType> : NSProxy

//filterSelector 返回YES的方法 才能applyToTarget
-(id)initWithTargetClass:(Class)targetClass filter:(BOOL(^)(SEL))filterSelector;
-(id)initWithTargetClass:(Class)targetClass;

/// 把方法应用与object
/// @param target target
/// @param clean 清除所有方法，默认yes，如果为NO，可以多次调用此方法
-(void)applyToTarget:(NSObject*)target clean:(BOOL)clean;
-(void)applyToTarget:(NSObject*)target;

/// 主动清理方法缓存,如果applyToTarget:clean: clean = NO 的话，需要主动清理
-(void)clean;

@end

NS_ASSUME_NONNULL_END

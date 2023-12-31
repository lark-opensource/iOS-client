//
//  NSObject+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (BTDAdditions)

/**
 调用一个指定的方法，可以传递多个参数。如果这个方法返回的是基本数据类型，会将返回值包装成一个NSNumber，如果这个方法的返回类型是void，会返回nil

 @param sel 方法的标识
  @param ... 可变参数，参数类型一定要匹配方法声明的类型，否则可能会出错
 @return 返回方法的返回结果
 
 Sample Code:
 
 // no variable args
 [view performSelectorWithArgs:@selector(removeFromSuperView)];
 
 // variable arg is not object
 [view performSelectorWithArgs:@selector(setCenter:), CGPointMake(0, 0)];
 
 // perform and return object
 UIImage *image = [UIImage.class performSelectorWithArgs:@selector(imageWithData:scale:), data, 2.0];
 
 // perform and return wrapped number
 NSNumber *lengthValue = [@"hello" performSelectorWithArgs:@selector(length)];
 NSUInteger length = lengthValue.unsignedIntegerValue;
 
 // perform and return wrapped struct
 NSValue *frameValue = [view performSelectorWithArgs:@selector(frame)];
 CGRect frame = frameValue.CGRectValue;
 */
- (nullable id)btd_performSelectorWithArgs:(nonnull SEL)sel, ...;

/**
 在当前线程延迟执行方法

 @param sel 方法的标识
 @param ... 可变参数，参数类型一定要匹配方法声明的类型，否则可能会出错
 @param delay 延迟的时间 ，单位 秒
 Sample Code:
 
 // no variable args
 [view performSelectorWithArgs:@selector(removeFromSuperView) afterDelay:2.0];
 
 // variable arg is not object
 [view performSelectorWithArgs:@selector(setCenter:), afterDelay:0, CGPointMake(0, 0)];
 */
- (void)btd_performSelectorWithArgs:(nonnull SEL)sel afterDelay:(NSTimeInterval)delay, ...;

/**
 在主线程执行方法，如果这个方法返回的是基本数据类型，会将返回值包装成一个NSNumber，如果这个方法的返回类型是void或者wait为YES会返回nil

 @param sel 方法的标识
 @param wait 如果为YES,会阻塞当前线程直到主线程执行完毕，如果为NO,不会阻塞当前线程
 @param ... 可变参数，参数类型一定要匹配方法声明的类型，否则可能会出错
 @return 返回方法的返回结果
 Sample Code:
 
 // no variable args
 [view performSelectorWithArgsOnMainThread:@selector(removeFromSuperView), waitUntilDone:NO];
 
 // variable arg is not object
 [view performSelectorWithArgsOnMainThread:@selector(setCenter:), waitUntilDone:NO, CGPointMake(0, 0)];
 */
- (nullable id)btd_performSelectorWithArgsOnMainThread:(nonnull SEL)sel waitUntilDone:(BOOL)wait, ...;

/**
 在特定线程执行方法，如果这个方法返回的是基本数据类型，会将返回值包装成一个NSNumber，如果这个方法的返回类型是void或者wait为YES会返回nil

 @param sel 方法的标识
 @param thread 执行方法的线程
 @param ... 可变参数，参数类型一定要匹配方法声明的类型，否则可能会出错
 @param wait 如果为YES,会阻塞当前线程直到特定线程执行完毕，如果为NO,不会阻塞当前线程
 @return 返回方法的返回结果
 */
- (nullable id)btd_performSelectorWithArgs:(nonnull SEL)sel onThread:(nonnull NSThread *)thread waitUntilDone:(BOOL)wait, ...;

/**
 在后台线程执行方法

 @param sel 方法的标识
 @param ... 可变参数，参数类型一定要匹配方法声明的类型，否则可能会出错
 */
- (void)btd_performSelectorWithArgsInBackground:(nonnull SEL)sel, ...;

/**
 交换两个对象方法

 @param origSelector 老方法的标识
 @param newSelector 新方法的标识
 @return 交换成功返回YES,否则返回NO
 */
+ (BOOL)btd_swizzleInstanceMethod:(nonnull SEL)origSelector with:(nonnull SEL)newSelector;

/**
 交换两个类方法

 @param origSelector 老方法标识
 @param newSelector 新方法标识
 @return 交换成功返回YES,否则返回NO
 */
+ (BOOL)btd_swizzleClassMethod:(nonnull SEL)origSelector with:(nonnull SEL)newSelector;

/**
 获取类名
 */
- (nonnull NSString *)btd_className;
+ (nonnull NSString *)btd_className;

/**
 对于NSDictionary，NSArray内部内容进行检查，返回一个新的NSDictionary，NSArray，使得NSDictionary，NSArray更为安全的操作
 @return 一个新的对象
 */
- (nullable id)btd_safeJsonObject;

/**
 Set the associated object.
 */

- (void)btd_attachObject:(nullable id)obj forKey:(NSString *)key;
- (nullable id)btd_getAttachedObjectForKey:(NSString *)key;

- (void)btd_attachObject:(nullable id)obj forKey:(NSString *)key isWeak:(BOOL)bWeak;
- (nullable id)btd_getAttachedObjectForKey:(NSString *)key isWeak:(BOOL)bWeak;

@end

NS_ASSUME_NONNULL_END

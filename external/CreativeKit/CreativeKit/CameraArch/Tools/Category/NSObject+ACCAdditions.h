//
//  NSObject+ACCAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/1.
//

#import <Foundation/Foundation.h>

@interface NSObject (ACCAdditions)

/**
 A call to a specified method can pass multiple parameters. If this method returns a basic data type, it will wrap the return value as an NSNumber, if this method returns a void type, it will return nil

 @param sel The identifier of the method
  @param ... Variable parameter, the parameter type must match the type declared by the method, otherwise there may be an error
 @return returns the result of the method

Translated with www.DeepL.com/Translator (free version)
 
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
- (nullable id)acc_performSelectorWithArgs:(nonnull SEL)sel, ...;

/**
 Delay the execution of the method in the current thread

 @param sel method identifier
 @param ... Variable parameter, the type of the parameter must match the type declared by the method, otherwise an error may occur
 @param delay the amount of time to delay, in seconds
 Sample Code:
 
 // no variable args
 [view performSelectorWithArgs:@selector(removeFromSuperView) afterDelay:2.0];
 
 // variable arg is not object
 [view performSelectorWithArgs:@selector(setCenter:), afterDelay:0, CGPointMake(0, 0)];
 */
- (void)acc_performSelectorWithArgs:(nonnull SEL)sel afterDelay:(NSTimeInterval)delay, ...;

/**
 Execute the method in the main thread, if the method returns a basic data type it will wrap the return value in an NSNumber, if the method returns a void or wait is YES it will return nil

 @param sel The identifier of the method
 @param wait will block the current thread until the main thread is finished if YES, and will not block the current thread if NO
 @param ... Variable parameter, the parameter type must match the type declared by the method, otherwise there may be an error
 @return returns the result of the method
 Sample Code:
 
 // no variable args
 [view performSelectorWithArgsOnMainThread:@selector(removeFromSuperView), waitUntilDone:NO];
 
 // variable arg is not object
 [view performSelectorWithArgsOnMainThread:@selector(setCenter:), waitUntilDone:NO, CGPointMake(0, 0)];
 */
- (nullable id)acc_performSelectorWithArgsOnMainThread:(nonnull SEL)sel waitUntilDone:(BOOL)wait, ...;

/**
 Execute the method on a specific thread, if the method returns a basic data type it will wrap the return value in an NSNumber, if the method returns a void or wait YES it will return nil

 @param sel The identifier of the method
 @param thread the thread in which the method is executed
 @param ... Variable parameter, the type of the parameter must match the type of the method declaration, otherwise there may be an error
 @param wait if YES, blocks the current thread until the particular thread is finished, if NO, does not block the current thread
 @return returns the result of the method
 */
- (nullable id)acc_performSelectorWithArgs:(nonnull SEL)sel onThread:(nonnull NSThread *)thread waitUntilDone:(BOOL)wait, ...;

/**
 Execute the method in a background thread

 @param sel method identifier
 @param ... Variable parameters, the parameter type must match the type of the method declaration, otherwise an error may occur
 */
- (void)acc_performSelectorWithArgsInBackground:(nonnull SEL)sel, ...;

/**
 Exchange of two instance methods

 @param origSelector Identifier of the old method
 @param newSelector The identifier of the new method
 @return YES for successful exchange, NO otherwise
 */
+ (BOOL)acc_swizzleInstanceMethod:(nonnull SEL)origSelector with:(nonnull SEL)newSelector;

/**
 Swap two class methods

 @param origSelector old method identifier
 @param newSelector new method identifier
 @return YES for successful exchange, NO otherwise
 */
+ (BOOL)acc_swizzleClassMethod:(nonnull SEL)origSelector with:(nonnull SEL)newSelector;

/**
 Get class name
 */
- (nonnull NSString *)acc_className;
+ (nonnull NSString *)acc_className;

/**
 For NSDictionary, NSArray internal content inspection, return a new NSDictionary, NSArray, making NSDictionary, NSArray safer to manipulate
 @return a new object
 */
- (nullable id)acc_safeJsonObject;

/**
 enumerate Implementation of Selector in current class
 class_copyMethodList called inner.
 */
+ (void)enumerateImplementationOfSelector:(SEL)sel UsingBlock:(void (^_Nullable)(IMP imp, BOOL *stop))block;

+ (NSInteger)implementationCountOfSelector:(SEL)sel;

/**
 enumerate registered classes, Note that clz is an __unsafe_unretained obj
 objc_getClassList called inner.
 */
+ (void)enumerateRegisteredClasses:(void (^)(Class clz, BOOL *stop))block;

+ (BOOL)isClassDescendsFromNSObject:(Class)clz;

/// check this class for repeat implemention of protocols instance methods that required; return selctor string if find one.
+ (NSString *)repeatSelectorImpOfProtocol:(NSArray *)protocols;

@end

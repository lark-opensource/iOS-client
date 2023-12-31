//
//  AWEAppContext.h
//  Pods
//
//  Created by liurihua on 2018/7/20.
//

#import <Foundation/Foundation.h>
#import <HTSServiceKit/HTSServiceCenter.h>

// Lightweight dependency injection framework
// Each module can bind the object that implements the protocol to the appContext through the bind method, and other modules dynamically obtain the object that implements the protocol through the objectForProtocol: method
// Interface and implementation are separated, other modules only need to care about the protocol interface function, do not need to care about the specific implementation, or even the specific class of implementation
// The module can also be decoupled by this method

#define APPContextIMP(PROTOCOL) ((id<PROTOCOL>)[[AWEAppContext appContext] objectForProtocol:@protocol(PROTOCOL)])

NS_ASSUME_NONNULL_BEGIN

@class AWEAppContext;
typedef id(^IESAppContextProvider)(AWEAppContext *context);

@interface AWEAppContext : NSObject

@property (class, readonly, nonatomic, strong) AWEAppContext *appContext NS_SWIFT_NAME(shared);

/**
 Bind the specific object that implements the protocol to the appContext, such as the unique object inside the module or the global singleton
 appContext weakly references object, object is destroyed, and automatically unbound

 @param object object
 @param protocol protocol
 @return Binding is successful return YES, if object is nil, or object does not implement protocol return NO
 */
- (BOOL)bind:(nullable id)object forProtocol:(Protocol *)protocol;

/**
 If the object to be bound is not fixed, but dynamically created at runtime, you need to create dynamic binding through the bandClass: method
 objectForProtocol: First get the bound class, then simply call id object = [class alloc] init] method to dynamically generate the object, and return object;
Since the class object is a global variable and will not be destroyed, it will not be unbound

 @param clazz class
 @param protocol protocol
 @return Binding is successful return YES; If clazz is nil, or clazz does not implement protocol, return NO
 */
- (BOOL)bindClass:(nullable Class)clazz forProtocol:(Protocol *)protocol;

/**
 If the object to be bound is not fixed, but dynamically created at runtime, and the dynamically generated object is not dynamically created by simply calling the [class alloc] init] method, you need to use the bindProvider: method to let the developer manage the dynamics themselves Object creation
 objectForProtocol: First obtain the bound provider, then call id object = provider(self) to dynamically generate an object that implements the protocol, and return the object; if the object does not implement the protocol, return nil;
 Developers can dynamically create objects that implement protocol in the provider block
 privoder is copied to appContext through NSPointerFunctionsCopyIn, so it will not be unbound

 @param provider IESAppContextProvider type block
 @param protocol protocol
 @return Binding is successful return YES; If provider is nil or protocol is nil, return NO
 */
- (BOOL)bindProvider:(nullable IESAppContextProvider)provider forProtocol:(nullable Protocol *)protocol;

/**
 Dynamically obtain objects that implement protocol
 In the method implementation, the object will be searched first, and if it is found, it will return the object;
 If no object is found, search for class again, if found, retrn id object = [[class alloc] init];
 If the class is not found, look for the provider again, if found, return id object = provider(self);
 didn't find it then return nil;
 
 @param protocol protocol
 @return object
 */
- (nullable id)objectForProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END

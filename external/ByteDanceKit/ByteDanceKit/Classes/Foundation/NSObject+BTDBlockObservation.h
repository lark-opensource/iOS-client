//
//  NSObject+BTDBlockObservation.h
//  BlocksKit
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Blocks wrapper for key-value observation.
 
 The code is referenced from [BlocksKit](https://github.com/BlocksKit/BlocksKit)

 In Mac OS X Panther, Apple introduced an API called "key-value
 observing."  It implements an [observer pattern](http://en.wikipedia.org/wiki/Observer_pattern),
 where an object will notify observers of any changes in state.

 NSNotification is a rudimentary form of this design style;
 KVO, however, allows for the observation of any change in key-value state.
 The API for key-value observation, however, is flawed, ugly, and lengthy.

 Like most of the other block abilities in BlocksKit, observation saves
 and a bunch of code and a bunch of potential bugs.

 Includes code by the following:

 - [Andy Matuschak](https://github.com/andymatuschak)
 - [Jon Sterling](https://github.com/jonsterling)
 - [Zach Waldowski](https://github.com/zwaldowski)
 - [Jonathan Wight](https://github.com/schwa)
 */

#pragma mark - Key Value Observation

@interface NSObject (BTDBlockObservation)

/** Adds an observer to an object conforming to NSKeyValueObserving.

 Adds a block observer that executes a block upon a state change.

 @param keyPath The property to observe, relative to the receiver.
 @param task A block with no return argument, and a single parameter: the receiver.
 @return Returns a globally unique process identifier for removing
 observation with removeObserverWithBlockToken:.
 @see addObserverForKeyPath:identifier:options:task:
 */
- (NSString *)btd_addObserverForKeyPath:(NSString *)keyPath task:(void (^)(id target))task;

/** Adds an observer to an object conforming to NSKeyValueObserving.

 Adds a block observer that executes the same block upon
 multiple state changes.

 @param keyPaths An array of properties to observe, relative to the receiver.
 @param task A block with no return argument and two parameters: the
 receiver and the key path of the value change.
 @return A unique identifier for removing
 observation with removeObserverWithBlockToken:.
 @see addObserverForKeyPath:identifier:options:task:
 */
- (NSString *)btd_addObserverForKeyPaths:(NSArray *)keyPaths task:(void (^)(id obj, NSString *keyPath))task;

/** Adds an observer to an object conforming to NSKeyValueObserving.

 Adds a block observer that executes a block upon a state change
 with specific options.

 @param keyPath The property to observe, relative to the receiver.
 @param options The NSKeyValueObservingOptions to use.
 @param task A block with no return argument and two parameters: the
 receiver and the change dictionary.
 @return Returns a globally unique process identifier for removing
 observation with removeObserverWithBlockToken:.
 @see addObserverForKeyPath:identifier:options:task:
 */
- (NSString *)btd_addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options task:(void (^)(id obj, NSDictionary *change))task;

/** Adds an observer to an object conforming to NSKeyValueObserving.

 Adds a block observer that executes the same block upon
 multiple state changes with specific options.

 @param keyPaths An array of properties to observe, relative to the receiver.
 @param options The NSKeyValueObservingOptions to use.
 @param task A block with no return argument and three parameters: the
 receiver, the key path of the value change, and the change dictionary.
 @return A unique identifier for removing
 observation with removeObserverWithBlockToken:.
 @see addObserverForKeyPath:identifier:options:task:
 */
- (NSString *)btd_addObserverForKeyPaths:(NSArray *)keyPaths options:(NSKeyValueObservingOptions)options task:(void (^)(id obj, NSString *keyPath, NSDictionary *change))task;

/** Adds an observer to an object conforming to NSKeyValueObserving.

 Adds a block observer that executes the block upon a
 state change.

 @param keyPath The property to observe, relative to the receiver.
 @param token An identifier for the observation block.
 @param options The NSKeyValueObservingOptions to use.
 @param task A block responding to the receiver and the KVO change.
 observation with removeObserverWithBlockToken:.
 @see addObserverForKeyPath:task:
 */
- (void)btd_addObserverForKeyPath:(NSString *)keyPath identifier:(NSString *)token options:(NSKeyValueObservingOptions)options task:(void (^)(id obj, NSDictionary *change))task;

/** Adds an observer to an object conforming to NSKeyValueObserving.

 Adds a block observer that executes the same block upon
 multiple state changes.

 @param keyPaths An array of properties to observe, relative to the receiver.
 @param token An identifier for the observation block.
 @param options The NSKeyValueObservingOptions to use.
 @param task A block responding to the receiver, the key path, and the KVO change.
 observation with removeObserversWithIdentifier:.
 @see addObserverForKeyPath:task:
 */
- (void)btd_addObserverForKeyPaths:(NSArray *)keyPaths identifier:(NSString *)token options:(NSKeyValueObservingOptions)options task:(void (^)(id obj, NSString *keyPath, NSDictionary *change))task;

/** Removes a block observer.

 @param keyPath The property to stop observing, relative to the receiver.
 @param token The unique key returned by addObserverForKeyPath:task:
 or the identifier given in addObserverForKeyPath:identifier:task:.
 @see removeObserversWithIdentifier:
 */
- (void)btd_removeObserverForKeyPath:(NSString *)keyPath identifier:(NSString *)token;

/** Removes multiple block observers with a certain identifier.

 @param token A unique key returned by addObserverForKeyPath:task:
 and addObserverForKeyPaths:task: or the identifier given in
 addObserverForKeyPath:identifier:task: and
 addObserverForKeyPaths:identifier:task:.
 @see removeObserverForKeyPath:identifier:
 */
- (void)btd_removeObserversWithIdentifier:(NSString *)token;

/** Remove all registered block observers. */
- (void)btd_removeAllBlockObservers;

@end

#pragma mark - Notification Observation

@interface NSObject (BTDBlockNotificationObservation)

/**
 Adds an entry to the notification center to receive notifications that passed to the provided block.
 
 [self btd_addObserverForNotification:notification object:obj queue:queue task:task] is Just like
 id observer = [[NSNotificationCenter defaultCenter] addObserverForName:notification object:obj queue:queue usingBlock:task].
 The returned object observer will attached to self and [[NSNotificationCenter defaultCenter] removeObserver:observer] will be called automatically when self deallc to avoid retain cycle leak.
 @return A unique identifier for removing observation with btd_removeNotificationObserverWithIdentifier:.
 */
- (nullable NSString *)btd_addObserverForNotification:(NSNotificationName _Nullable )notification object:(nullable id)obj queue:(NSOperationQueue *_Nullable)queue task:(void (^_Nonnull)(NSNotification * _Nonnull note))task;

/**
 A convenient version of the above method.
 When the caller does not care about the notification sender or the operation queue where the task block runs, here is a more convenient way.
 Use [self btd_addObserverForNotification:notification task:task] is just the same as [self btd_addObserverForNotification:notification object:nil queue:nil task:task]
 */
- (nullable NSString *)btd_addObserverForNotification:(NSNotificationName _Nullable)notification task:(void (^_Nonnull)(NSNotification * _Nonnull note))task;

/**
 Removes a notification block observer. ( Just like [[NSNotificationCenter defaultCenter] removeObserver:observer] )
 */
- (void)btd_removeNotificationObserverWithIdentifier:(NSString *_Nullable)token;

/**
 Removes the matching entries from the receiver’s dispatch table. ( Just like [[NSNotificationCenter defaultCenter] removeObserver:observer name:aName object:anObject] )
 */
- (void)btd_removeNotificationObserverWithIdentifier:(NSString *_Nullable)token name:(nullable NSNotificationName)c object:(nullable id)anObject;

/**
 Remove all registered notification block observers attached to self.
 */
- (void)btd_removeAllNotificationObservers;

@end

NS_ASSUME_NONNULL_END

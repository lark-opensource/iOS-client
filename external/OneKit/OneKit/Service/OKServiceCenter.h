//
//  OKServiceCenter.h
//  OneKit
//
//  Created by bob on 2020/5/11.
//

#import <Foundation/Foundation.h>

@protocol OKService;


NS_ASSUME_NONNULL_BEGIN

@interface OKServiceCenter : NSObject

+ (instancetype)sharedInstance;

/// class should implement OKService
- (void)bindClass:(Class)cls forProtocol:(Protocol *)protocol;
/// object should implement OKService
- (void)bindObject:(id)service forProtocol:(Protocol *)protocol;
- (nullable id)serviceForProtocol:(Protocol *)protocol;

@end

#ifndef OK_CENTER
#define OK_CENTER
#define OK_CENTER_OBJECT(theProtocol) \
    [[OKServiceCenter sharedInstance] serviceForProtocol:@protocol(theProtocol)]

#define OK_CENTER_BIND_CLASS_PROTOCOL(theClass, theProtocol) \
    [[OKServiceCenter sharedInstance] bindClass:theClass forProtocol:@protocol(theProtocol)]

#define OK_CENTER_BIND_OBJECT_PROTOCOL(theObject, theProtocol) \
    [[OKServiceCenter sharedInstance] bindObject:theObject forProtocol:@protocol(theProtocol)]

#endif

NS_ASSUME_NONNULL_END

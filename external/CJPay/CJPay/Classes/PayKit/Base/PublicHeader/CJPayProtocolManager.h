//
//  CJPayProtocolManager.h
//  CJPay
//
//  Created by 王新华 on 3/4/20.
//

#import <Foundation/Foundation.h>
#import "CJPayPublicServiceHeader.h"

#define CJ_CLASS_WITH_PROCOCOL(pro) ((Class)([CJPayProtocolManager getClassWithProtocol:@protocol(pro)]))

#define CJ_OBJECT_WITH_PROTOCOL(pro) ((id<pro>)([CJPayProtocolManager getObjectWithProtocol:@protocol(pro)]))

#define CJ_DECLARE_ID_PROTOCOL(pro) id<pro> objectWith##pro = CJ_OBJECT_WITH_PROTOCOL(pro)

#define CJPayRegisterCurrentService(object,pro) [CJPayProtocolManager bindObject:object toProtocol:@protocol(pro)];
// 绑定class到protocol。会默认使用[[cls alloc] init] 进行实例的创建
#define CJPayRegisterCurrentClassToPtocol(class,pro) [CJPayProtocolManager bindClass:class toProtocol:@protocol(pro)];

// 绑定class到protocol。指定单例方法，会按照指定的单例方法进行初始化，注意该方法不接收参数
#define CJPayRegisterCurrentClassWithSharedSelectorToPtocol(class,sel,pro) [CJPayProtocolManager bindClass:class withSharedSelector:sel toProtocol:@protocol(pro)];

NS_ASSUME_NONNULL_BEGIN

@interface CJPayProtocolManager : NSObject

+ (void)bindObject:(id)object toProtocol:(Protocol *)protocol;
+ (void)bindClass:(Class)class toProtocol:(Protocol *)protocol;
+ (void)bindClass:(Class)class withSharedSelector:(nullable SEL)sharedSelector toProtocol:(Protocol *)protocol;

+ (nullable id)getObjectWithProtocol:(Protocol *)protocol;
+ (nullable Class)getClassWithProtocol:(Protocol *)protocol;

+ (void)unbindProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END

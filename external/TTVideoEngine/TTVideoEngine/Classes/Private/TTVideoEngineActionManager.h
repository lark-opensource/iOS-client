//
//  TTVideoEngineActionManager.h
//  TTVideoEngine
//
//  Created by shen chen on 2021/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineActionManager : NSObject

+ (instancetype)shareInstance;

- (void)registerActionObj:(id)obj forProtocol:(Protocol *)protocol;

- (void)removeActionObj:(id)obj forProtocol:(Protocol *)protocol;

- (id)actionObjWithProtocal:(Protocol *)protocol;

- (void)registerActionClass:(Class)class forProtocol:(Protocol *)protocol;

- (Class)actionClassWithProtocal:(Protocol *)protocol;

- (void)removeActionClass:(Class)class forProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END

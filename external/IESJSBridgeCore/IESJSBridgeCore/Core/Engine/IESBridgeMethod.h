//
//  IESBridgeMethod.h
//  IESWebKit
//
//  Created by li keliang on 2019/4/8.
//

#import <Foundation/Foundation.h>
#import <IESJSBridgeCore/IESBridgeDefines.h>
#import <BDJSBridgeAuthManager/IESBridgeAuthManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESBridgeMethod : NSObject

@property (nonatomic, readonly, assign) IESPiperAuthType authType;
@property (nonatomic, readonly,   copy) NSString *methodName;
@property (nonatomic, readonly,   copy) NSString *methodNamespace;
@property (nonatomic, readonly,   copy) IESBridgeHandler handler;

- (instancetype)initWithMethodName:(NSString *)methodName methodNamespace:(NSString *)methodNamespace authType:(IESPiperAuthType)authType handler:(IESBridgeHandler)handler;

@end

NS_ASSUME_NONNULL_END

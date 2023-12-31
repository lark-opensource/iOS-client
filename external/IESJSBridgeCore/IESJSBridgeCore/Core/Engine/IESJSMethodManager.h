//
//  IESJSMethodManager.h
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/7/19.
//

#import <Foundation/Foundation.h>
#import "IESBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const IESJSMethodKeyInvokeMethod;
extern NSString * const IESJSMethodKeyHandleMessageFromNative;
extern NSString * const IESJSMethodKeyFetchQueue;
extern NSString * const IESJSMethodKeyHanlderName;

extern NSString * const IESPiperOnMethodParamsHandler;

@interface IESJSMethod : NSObject

@property (nonatomic, copy, readonly) NSString *bridgeName;
@property (nonatomic, copy, readonly) NSString *methodName;
@property (nonatomic, copy, readonly) NSString *fullName;

@end


typedef void (^IESJSMethodQueryingHandler)(IESJSMethod * _Nullable method);
typedef void (^IESJSMethodCheckingHandler)(IESJSMethod *method, BOOL defined);

@protocol IESBridgeExecutor;

@interface IESJSMethodManager : NSObject

+ (instancetype)managerWithBridgeExecutor:(id<IESBridgeExecutor>)bridgeExecutor;

+ (NSString *)injectionScriptWithJSMethod:(IESJSMethod *)method messageHandler:(NSString *)messageHandler;
+ (NSString *)injectionScriptWithJSMethods:(NSArray<IESJSMethod *> *)methods messageHandler:(NSString *)messageHandler;

- (NSDictionary<IESPiperProtocolVersion, IESJSMethod *> *)allJSMethodsForKey:(NSString *)key;
- (NSArray<IESPiperProtocolVersion> *)allHandlerNames;

- (void)queryPreferredJSMethodForKey:(NSString *)key withHandler:(IESJSMethodQueryingHandler)handler;
- (void)checkAllJSMethodsDefinedForKey:(NSString *)key withHandler:(IESJSMethodCheckingHandler)handler;

- (void)deleteAllPipers;

@end

NS_ASSUME_NONNULL_END

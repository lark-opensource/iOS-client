//
//  IESBridgeAuthModel.h
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/8/29.
//

#import <Foundation/Foundation.h>
#import "IESBridgeAuthManager.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - IESBridgeAuthRule

@interface IESBridgeAuthRule : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSString *pattern;
@property (nonatomic, assign, readonly) IESPiperAuthType group;
@property (nonatomic, copy, readonly) NSArray<NSString *> *includedMethods;
@property (nonatomic, copy, readonly) NSArray<NSString *> *excludedMethods;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithPattern:(NSString *)pattern group:(IESPiperAuthType)group;

@end

#pragma mark - IESOverriddenMethodPackage

@interface IESOverriddenMethodPackage : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSMutableSet<NSString *> *publicMethods;
@property (nonatomic, strong, readonly) NSMutableSet<NSString *> *protectedMethods;
@property (nonatomic, strong, readonly) NSMutableSet<NSString *> *privateMethods;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (BOOL)containsMethodName:(NSString *)methodName;

@end

#pragma mark - IESBridgeAuthPackage

extern NSString * const IESBridgeAuthInfoChannel;

@interface IESBridgeAuthPackage : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSArray<IESBridgeAuthRule *> *> *content;
@property (nonatomic, strong, readonly) IESOverriddenMethodPackage *overriddenMethodPackage;
@property (nonatomic, assign, readonly, getter=isBridgeAuthInfo) BOOL bridgeAuthInfo;

@property (nonatomic, copy, readonly) NSString *namespace;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

@interface IESBridgeAuthRequestParams : NSObject

@property (nonatomic, copy) NSString *authDomain;
@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, copy) NSArray<NSString *> *extraChannels;

@property (nonatomic, copy) IESBridgeAuthCommonParamsBlock commonParams;

@end


NS_ASSUME_NONNULL_END

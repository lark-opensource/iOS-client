//
//  BDXBridgeDefinitions.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const BDXBridgeErrorDomain;
extern NSString const *BDXBridgeALogTag;

typedef NS_OPTIONS(NSUInteger, BDXBridgeEngineType) {
    BDXBridgeEngineTypeWeb = 1 << 0,
    BDXBridgeEngineTypeLynx = 1 << 1,
    BDXBridgeEngineTypeRN = 1 << 2,
    BDXBridgeEngineTypeTimor = 1 << 3,
    BDXBridgeEngineTypeAll = BDXBridgeEngineTypeWeb | BDXBridgeEngineTypeLynx | BDXBridgeEngineTypeRN | BDXBridgeEngineTypeTimor,
};

typedef NS_ENUM(NSUInteger, BDXBridgeAuthType) {
    BDXBridgeAuthTypePublic = 0,
    BDXBridgeAuthTypeProtected,
    BDXBridgeAuthTypePrivate,
    BDXBridgeAuthTypeSecure,
};

typedef NS_ENUM(NSInteger, BDXBridgeStatusCode) {
    // General Errors
    BDXBridgeStatusCodeSucceeded = 1,
    BDXBridgeStatusCodeFailed = 0,
    BDXBridgeStatusCodeUnauthorizedInvocation = -1,
    BDXBridgeStatusCodeUnregisteredMethod = -2,
    BDXBridgeStatusCodeInvalidParameter = -3,
    BDXBridgeStatusCodeInvalidNamespace = -4,
    BDXBridgeStatusCodeInvalidResult = -5,
    BDXBridgeStatusCodeUnauthorizedAccess = -6,
    BDXBridgeStatusCodeOperationCancelled = -7,
    BDXBridgeStatusCodeOperationTimeout = -8,
    BDXBridgeStatusCodeNotFound = -9,
    BDXBridgeStatusCodeNotImplemented = -10,
    BDXBridgeStatusCodeAlreadyExists = -11,
    BDXBridgeStatusCodeUnknown = -1000,
    
    // Network Errors
    BDXBridgeStatusCodeNetworkUnreachable = -1001,
    BDXBridgeStatusCodeNetworkTimeout = -1002,
    BDXBridgeStatusCodeMalformedResponse = -1003,
    
    // Business layer may define their own status code, which should start from 10001.
    // Status code <= 10000 will be reserved for BDXBridgeKit.
};

NS_ASSUME_NONNULL_END

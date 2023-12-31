//
//  BDTrustEnclave+Private.h
//  BDTrustEnclave
//
//  Created by ….ok@bytedance.com on 2022/6/4.
//

#import <Foundation/Foundation.h>
#import "BDTGKeyPair.h"


@interface BDTGPrivateKeyManager : NSObject

@property (nonatomic, copy, readonly, nonnull) NSString *keyType;

@property (nonatomic, assign, readonly) NSInteger isFromCache;

- (SecKeyRef _Nullable)privateKeySync;
- (SecKeyRef _Nullable)privateKeyWithTimeout:(NSTimeInterval)timeout;
- (SecKeyRef _Nullable)privateKeyWithTimeout:(NSTimeInterval)timeout error:(NSError *_Nullable *_Nullable)error;
- (void)loadPrivateKeyWithScene:(NSString *_Nullable)scene completion:(nullable void (^)(SecKeyRef _Nullable))completion;

- (NSString *_Nullable)publicKeyBase64;

- (void)preloadECDHKeyAsync;

- (NSData *_Nullable)ecdhKey NS_AVAILABLE_IOS(11.0);
- (NSData *_Nullable)ecdhKey:(NSError *_Nullable *_Nullable)error NS_AVAILABLE_IOS(11.0);

@end


@interface BDTGTEEPrivateKeyManager : BDTGPrivateKeyManager

+ (NSInteger)checkLocalCertWithPrivateKey:(SecKeyRef _Nullable)privateKey;

@end


@interface BDTGREEPrivateKeyManager : BDTGPrivateKeyManager

@end

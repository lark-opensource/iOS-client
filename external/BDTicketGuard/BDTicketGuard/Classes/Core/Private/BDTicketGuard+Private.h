//
//  BDTicketGuard+Private.h
//  BDTicketGuard
//
//  Created by ByteDance on 2022/12/21.
//

#import "BDTicketGuard.h"
#import "BDTGKeyPair.h"
#import "BDTGPrivateKeyManager.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDTicketGuard (Private)

@property (class, nonatomic, strong, readonly, nonnull) BDTGPrivateKeyManager *teeKeyManager;
@property (class, nonatomic, strong, readonly, nonnull) BDTGPrivateKeyManager *reeKeyManager;

@property (class, nonatomic, assign, readonly) BOOL teeHasFailedBefore;

+ (BOOL)hasGeneratedForKeyType:(NSString *_Nonnull)keyType;
+ (void)setHasGeneratedForKeyType:(NSString *_Nonnull)keyType;

+ (void)setTeeHasFailed;

@end


@interface BDTicketGuard (PrivateKeyType)

- (void)resetKeyType:(NSString *_Nonnull)keyType;

@end

NS_ASSUME_NONNULL_END

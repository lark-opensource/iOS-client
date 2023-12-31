//
//  SGMSafeGuardConfigPrivate.h
//  Pods
//
//  Created by jianghaowne on 2018/4/10.
//

#ifndef SGMSafeGuardConfigPrivate_h
#define SGMSafeGuardConfigPrivate_h

#import "SGMSafeGuardConfig.h"
#import "SGMSafeGuradProtocols.h"

#define SGM_LOCAL_STRING(key) NSLocalizedStringFromTableInBundle(key, nil, [sgm_globalConfig() sgmBundle], nil)

@protocol SGMSafeGuardHybridDelegate <SGMSafeGuardDelegate>

@optional

- (NSString *)sgm_hostType;

- (NSString *)sgm_appKey;

@end

__BEGIN_DECLS

SGMSafeGuardConfig *sgm_globalConfig(void);

__END_DECLS

extern NSObject <SGMSafeGuardHybridDelegate> *hybridDelegate;

@interface SGMSafeGuardConfig ()

@property (atomic) SGMSafeGuardHostType hostType; ///< host区域

@property (atomic, copy) NSString *appID; ///< appID

@property (atomic, copy) NSString *domain;

@property (atomic, weak) id<SGMSafeGuardDelegate> delegate;

#if DEBUG || TEST || SGM_INHOUSE
@property (nonatomic) BOOL isTestHost; ///< 是否使用测试域名
#endif

- (NSBundle *)sgmBundle;
- (NSString *)commonParamsQueryString;
- (NSDictionary *)queryParasDictionary;
#ifdef _URL_V3
- (NSDictionary *)commonInfoForPostRequest;
#endif
- (NSDictionary *)hybrid_queryParasDictionary;
- (NSDictionary *)UDIDInfoForPostRequest;
- (NSString *)retFromDelegateSelector:(SEL)delegateSEL;
- (NSString *)hybrid_RetFromDelegateSelector:(SEL)delegateSEL;
- (BOOL)isUseTTNet;
@end

#endif /* SGMSafeGuardConfigPrivate_h */

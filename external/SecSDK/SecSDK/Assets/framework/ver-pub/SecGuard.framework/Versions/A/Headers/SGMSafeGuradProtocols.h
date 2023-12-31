//
//  SGMSafeGuradProtocols.h
//  SecGuard
//
//  Created by jianghaowne on 2019/1/18.
//

#ifndef SGMSafeGuradProtocols_h
#define SGMSafeGuradProtocols_h

#import "SGMPreMacros.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SGMVerificationProtocol <NSObject>

@required

+ (instancetype)sharedManager;
- (void)onSDKInit:(void (^_Nullable)())completion;
- (void)popupVerificationViewOfScene:(NSString *)scene type:(SGMVerifyType)type languageCode:(NSString *)languageCode presentingView:(UIView *)presentingView callback:(SGMVerificationCallback)callback;

@end

@protocol SGMEncrptProtocol <NSObject>

@required

+ (instancetype)sharedInstance;

- (void)adjustWithServerTime:(long long)serverTime;

@end

@protocol SGMSelasOptionProtocol <NSObject>

@required

@property(readwrite) NSString *url;
@property(readwrite) NSString *region;
@property(readwrite) NSString *appId;

@end

@protocol SGMSelasProtocol <NSObject>

@required

+(instancetype)shareInstance;

- (void)create:(id<SGMSelasOptionProtocol>) opt;

- (NSString* _Nullable)getToken;

@end

#endif /* SGMSafeGuradProtocols_h */

NS_ASSUME_NONNULL_END

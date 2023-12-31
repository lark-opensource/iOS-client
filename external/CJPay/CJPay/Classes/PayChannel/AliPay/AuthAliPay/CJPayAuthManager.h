//
//  CJPayAuthManager.h
//  CJPay
//
//  Created by 王新华 on 3/2/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayAuthManager : NSObject

+ (instancetype)shared;
- (void)registerAuthAliPayScheme:(NSString *)scheme;
- (BOOL)canProcessURL:(NSURL *)url;
- (void)authAliPay:(NSString *)infoStr callback:(void(^)(NSDictionary *resultDic))callback;

@end

NS_ASSUME_NONNULL_END

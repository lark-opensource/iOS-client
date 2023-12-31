//
//  BDPAES256Utils.h
//  ECOInfra
//
//  Created by ByteDance on 2022/10/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OPAES256Utils : NSObject

+ (NSString *)encryptWithContent:(NSString *)content key:(NSString *)key iv:(NSString *)iv;
+ (NSString *)decryptWithContent:(NSString *)content key:(NSString *)key iv:(NSString *)iv;
+ (NSString *)getIV:(NSString *)ivInfo backup:(NSString *)backup;

@end

NS_ASSUME_NONNULL_END

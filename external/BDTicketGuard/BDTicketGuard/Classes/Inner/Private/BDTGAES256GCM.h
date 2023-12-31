//
//  BDTGAES256GCM.h
//  BDTicketGuard
//
//  Created by ByteDance on 2022/12/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface BDTGAES256GCM : NSObject

+ (NSData *_Nullable)encryptString:(NSString *)string hexKey:(NSString *)hexKey error:(NSError *__autoreleasing _Nullable *)error;

+ (NSString *_Nullable)decryptHexString:(NSString *)encryptedHexString hexKey:(NSString *)hexKey error:(NSError *__autoreleasing _Nullable *)error;

+ (NSData *_Nullable)decryptData:(NSData *)encryptedData key:(NSData *)key error:(NSError *__autoreleasing _Nullable *)error;

@end

NS_ASSUME_NONNULL_END

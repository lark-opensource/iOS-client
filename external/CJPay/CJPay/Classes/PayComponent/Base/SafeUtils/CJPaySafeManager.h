//
//  CJPaySafeManager.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/24.
//

#import <Foundation/Foundation.h>
#import "CJPayCommonSafeHeader.h"
#import "CJPayEngimaProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySafeManager : NSObject

+ (NSNumber *)secureInfoVersion;

+ (BOOL)isEngimaISec;

+ (id<CJPayEngimaProtocol>)buildEngimaEngine:(NSString *)engimaID;

+ (id<CJPayEngimaProtocol>)buildEngimaEngine:(NSString *)engimaID useCert:(NSString *)cert;
/**
 * 加密
 * 第一次调用encrypt是非对称的，需要将encrypt返回的密文发给服务端协商密钥，然后将服务端返回的密文传给decrypt解密。
 * 以后就可以直接调用encrypt了。
 *
 * @param data  要加密的数据，需要base64
 * @param errorCode 返回的错误码，在返回值为空的时候需要关注
 * @return 加密然后base64后的数据
 */
+ (NSString *)cj_encryptWith:(NSString *)data errorCode:(int *)errorCode;

/**
 * 加密
 * 第一次调用encrypt是非对称的，需要将encrypt返回的密文发给服务端协商密钥，然后将服务端返回的密文传给decrypt解密。
 * 以后就可以直接调用encrypt了。
 *
 * @param data  要加密的数据，需要base64
 * @param publicKey  加密公钥
 * @param errorCode 返回的错误码，在返回值为空的时候需要关注
 * @return 加密然后base64后的数据
 */
+ (NSString *)cj_encryptWith:(NSString *)data token:(NSString *)publicKey errorCode:(int *)errorCode;

/**
 * 解密
 * @param data  要解密的数据，需要base64
 * @param errorCode 返回的错误码，在返回值为空的时候需要关注
 * @return 解密然后base64后的数据
 */
+ (NSString *)cj_decryptWith:(NSString *)data errorCode:(int *)errorCode;

/**
* 同一个tfcc对象加密
*
* @param data  要加密的数据，需要base64
* @param errorCode 返回的错误码，在返回值为空的时候需要关注
* @return 加密然后base64后的数据
*/
+ (NSString*) cj_objEncryptWith:(NSString *)data errorCode:(int *)errorCode engimaEngine:(id<CJPayEngimaProtocol>)engimaImpl;


/**
* 同一个tfcc对象解密
* @param data  要解密的数据，需要base64
* @param errorCode 返回的错误码，在返回值为空的时候需要关注
* @return 解密然后base64后的数据
*/
+ (NSString *)cj_objDecryptWith:(NSString *)data engimaEngine:(id<CJPayEngimaProtocol>)engimaImpl errorCode:(int *)errorCode;


/**
 返回加密库的信息

 @return 包含加密库信息的字典
 */
+ (NSDictionary *)secureInfo;

+ (NSString *)encryptMediaData:(NSData *)mediaData tfccCert:(NSString *)tfccCert iSecCert:(NSString *)isecCert engimaVersion:(NSNumber **)engimaVersion;

@end

NS_ASSUME_NONNULL_END

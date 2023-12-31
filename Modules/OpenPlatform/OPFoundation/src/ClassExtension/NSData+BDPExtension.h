/**
 * @file NSDataAdditions
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief NSData的扩展
 * 
 * @details NSData 一些功能的扩展
 * 
 */


#import <Foundation/Foundation.h>

@interface NSData(BDPExtension)

/**
 *  RSA加密数据
 *
 *  @param data   待加密数据
 *  @param pubKey 公钥
 *  @param error  错误
 *
 *  @return 加密后的数据
 */
+ (NSData *)encryptData:(NSData *)data publicKey:(NSString *)pubKey error:(NSError **)error;

/**
 *  使用RSA对数据进行认证
 *
 *  @param data   待认证的数据
 *  @param pubKey 公钥
 *  @param error  错误信息
 *
 *  @return 认证后的数据
 */
+ (NSData *)decryptData:(NSData *)data publicKey:(NSString *)pubKey error:(NSError **)error;

/**
 *  将Base64格式的字符串转换成NSData
 *
 *  @param base64String Base64格式的字符串
 *
 *  @return 转换后的数据
 */
+ (NSData *)ss_dataWithBase64EncodedString:(NSString *)base64String;

/**
 *  将NSData转换成Base64格式字符串
 *
 *  @return 转换后的字符串
 */
- (NSString *)ss_base64EncodedString;


/**
 *  将NSData转换成MD5加密的字符串
 *
 *  @return 转换后的字符串
 */
- (NSString *)bdp_md5String;

/**
 *  将NSData数据转换成十六进制字符串
 *
 *  @return 转换后的字符串
 */
- (NSString *)hexadecimalString;

/// 将十六进制的字符串转换成 NSData
/// 如果字符串长度不为偶数，则自动在最前面的追加 0
/// @param hex 十六进制的字符串
+ (NSData *)dataWithHexString:(NSString *)hex;

/// gzip 压缩
/// @param level 压缩系数
- (nullable NSData *)bdp_gzippedDataWithCompressionLevel:(float)level;

/// gzip压缩 等同于 bdp_gzippedDataWithCompressionLevel(-1.0)
- (nullable NSData *)bdp_gzippedData;

/// gzip解压
- (nullable NSData *)bdp_gunzippedData;

/// 是否是gzip压缩过的数据
- (BOOL)bdp_isGzippedData;

- (NSString *)toHexString;


/// 判断传入data是否是webp 格式
+ (BOOL)isWebpData:(NSData  * _Nullable )data;

@end

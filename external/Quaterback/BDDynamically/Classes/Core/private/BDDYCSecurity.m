//
//  BDDYCSecurity.m
//  BDDynamically
//
//  Created by zuopengliu on 21/5/2018.
//

#import "BDDYCSecurity.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCrypto.h>
#import <Security/Security.h>



@implementation BDDYCSecurity

@end


#pragma mark - static methods

static NSString *bdd_MD5File(NSString *filePath)
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (!handle) return nil;
    
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    BOOL done = NO;
    while (!done) {
        NSData *fileData = [handle readDataOfLength:256];
        CC_MD5_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
        if ([fileData length] == 0) done = YES;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSString *result = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                        digest[0], digest[1],
                        digest[2], digest[3],
                        digest[4], digest[5],
                        digest[6], digest[7],
                        digest[8], digest[9],
                        digest[10], digest[11],
                        digest[12], digest[13],
                        digest[14], digest[15]];
    return result;
}

static NSString *bdd_MD5Data(id data /* NSString or NSData */)
{
    if (!data) return nil;
    const char *bytePtr = nil;
    if ([data isKindOfClass:[NSString class]]) {
        bytePtr = [(NSString *)data UTF8String];
    } else if ([data isKindOfClass:[NSData class]]) {
        bytePtr = [(NSData *)data bytes];
    } else {
        NSCAssert(NO, @"data type is error, must be NSString or NSData");
    }
    if (!bytePtr) return nil;
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(bytePtr, (CC_LONG)strlen(bytePtr), digest);
    NSString *result = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                        digest[0], digest[1],
                        digest[2], digest[3],
                        digest[4], digest[5],
                        digest[6], digest[7],
                        digest[8], digest[9],
                        digest[10], digest[11],
                        digest[12], digest[13],
                        digest[14], digest[15]];
    return result;
}

#pragma mark - base64

// encode data to base64 string
static NSString *bdd_base64Encode(NSData *data)
{
    if (!data) return nil;
    @try {
        NSString *base64EncodeStr = [data base64EncodedStringWithOptions:0];
        return base64EncodeStr;
    } @catch (NSException *expt) {
        NSCAssert(NO, @"base64 encode data failure: %@", data);
    } @finally {
    }
    return nil;
}

// decode base64 string to data
static NSData *bdd_base64Decode(NSString *text)
{
    if (!text) return nil;
    @try {
        NSData *base64Data = [[NSData alloc] initWithBase64EncodedString:text options:0];
        return base64Data;
    } @catch (NSException *expt) {
        NSCAssert(NO, @"base64 decode failure: %@", text);
    } @finally {
    }
    return nil;
}

#pragma mark - 对称加密 (AES)

static NSData *bdd_AESCryptData(BOOL operation,     /** 加密还是解密 YES: 加密，NO: 解密 */
                                NSData *txtData,    /** 待加密或解密的数据 */
                                NSData *iv          /** 初始化向量 */,
                                NSData *key         /** 密钥 */)
{
    if (!txtData) return nil;
    
    // check length of key and iv
    if (iv && [iv length] != 16) {
        NSCAssert(NO, @"AES Length of iv is wrong. Length of iv should be 16(128bits)");
        return nil;
    }
    if ([key length] != 32) {
        NSCAssert(NO, @"AES Length of key is wrong. Length of iv should be 16, 24 or 32 (128, 192 or 256bits)");
        return nil;
    }
    
    // 算法基本信息
    uint32_t keySize = kCCKeySizeAES256, blockSize = kCCBlockSizeAES128;
    uint32_t algorithm = kCCAlgorithmAES;
    
    // 根据初始化向量选择加密Mode
    // ECB kCCOptionPKCS7Padding (不需要初始化向量)
    // CBC kCCOptionPKCS7Padding | kCCOptionECBMode
    uint32_t option = 0; // mode
    if (iv) { // CBC
        option = kCCOptionPKCS7Padding | kCCOptionECBMode;
    } else { // ECB
        option = kCCOptionPKCS7Padding;
    }
    
    NSData *data = txtData;
    if ([txtData isKindOfClass:[NSString class]]) data = [(NSString *)txtData dataUsingEncoding:NSUTF8StringEncoding];
    NSCAssert([data isKindOfClass:[NSData class]], @"AES text data type is error, should be NSData");
    
    size_t moveoutDataSize = 0;
    size_t bufferSize = [data length] + blockSize;
    void *buffer = (void *)malloc(bufferSize);
    CCCryptorStatus cryptStatus = CCCrypt(operation ? kCCEncrypt : kCCDecrypt,
                                          algorithm,    // algorithm
                                          option,       // Mode
                                          [key bytes],  // key
                                          keySize,      // key length
                                          [iv bytes],   // initialization vector
                                          [data bytes], // data
                                          [data length],// data length
                                          buffer,
                                          bufferSize,
                                          &moveoutDataSize);
    
    NSData *result = nil;
    if (cryptStatus == kCCSuccess) {
        result = [NSData dataWithBytesNoCopy:buffer length:moveoutDataSize];
    } else {
        if (buffer) free(buffer);
        NSLog(@"AES encrypt/decrypt failure, status code: %d", cryptStatus);
    }
    return result;
}

static NSData *bdd_AESEncryptData(NSData *textData,
                                  NSData *iv,
                                  NSData *key /* 密钥 */)
{
    return bdd_AESCryptData(YES, textData, iv, key);
}

static NSData *bdd_AESDecryptData(NSData *textData,
                                  NSData *iv,
                                  NSData *key /* 密钥 */)
{
    return bdd_AESCryptData(NO, textData, iv, key);
}

#pragma mark - 非对称加密

static NSData *bdd_RSAStripPublicKeyHeader(NSData *d_key)
{
    // Skip ASN.1 public key header
    if (d_key == nil) return (nil);
    
    unsigned long len = [d_key length];
    if (!len) return (nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    
    if (c_key[idx++] != 0x30) return (nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return (nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return (nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return (nil);
    
    // Now make a new NSData from this buffer
    return ([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

static SecKeyRef bdd_RSAAddPublicKey(NSString *key)
{
    NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];
    if (spos.location != NSNotFound && epos.location != NSNotFound) {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    // This will be base64 encoded, decode it.
    NSData *data = bdd_base64Decode(key);
    data = bdd_RSAStripPublicKeyHeader(data);
    if (!data) { return nil; }
    
    NSString *tag = @"what_the_fuck_is_this";
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    // Add persistent version of the key to system keychain
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
     kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil) {
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }
    
    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if (status != noErr) {
        return nil;
    }
    return keyRef;
}

static NSData * bdd_RSAEncryptData(NSData *data, NSString *pubKey)
{
    if (!data || !pubKey) {
        return nil;
    }
    SecKeyRef keyRef = bdd_RSAAddPublicKey(pubKey);
    if (!keyRef) {
        return nil;
    }
    
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t outlen = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    if (srclen > outlen - 11) {
        CFRelease(keyRef);
        return nil;
    }    
    void *outbuf = malloc(outlen);
    OSStatus status = noErr;
    status = SecKeyEncrypt(keyRef,
                           kSecPaddingPKCS1,
                           srcbuf,
                           srclen,
                           outbuf,
                           &outlen
                           );
    NSData *ret = nil;
    if (status != 0) {
        //NSLog(@"SecKeyEncrypt fail. Error Code: %ld", status);
    } else {
        ret = [NSData dataWithBytes:outbuf length:outlen];
    }
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}

static NSData * bdd_RSADecryptData(NSData *data, NSString *pubKey)
{
    if (!data || !pubKey) {
        return nil;
    }
    SecKeyRef keyRef = bdd_RSAAddPublicKey(pubKey);
    if (!keyRef) {
        return nil;
    }
    
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t outlen = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    //    if(srclen != outlen){
    //        //TODO: currently we are able to decrypt only one block!
    //        CFRelease(keyRef);
    //        return nil;
    //    }
    UInt8 *outbuf = malloc(outlen);
    
    //use kSecPaddingNone in decryption mode
    OSStatus status = noErr;
    status = SecKeyDecrypt(keyRef,
                           kSecPaddingNone,
                           srcbuf,
                           srclen,
                           outbuf,
                           &outlen
                           );
    NSData *result = nil;
    if (status != 0) {
        //NSLog(@"SecKeyEncrypt fail. Error Code: %ld", status);
    } else {
        //the actual decrypted data is in the middle, locate it!
        int idxFirstZero = -1;
        int idxNextZero = (int)outlen;
        for (int i = 0; i < outlen; i++) {
            if (outbuf[i] == 0) {
                if (idxFirstZero < 0) {
                    idxFirstZero = i;
                } else {
                    idxNextZero = i;
                    break;
                }
            }
        }
        
        result = [NSData dataWithBytes:&outbuf[idxFirstZero+1] length:idxNextZero-idxFirstZero-1];
    }
    if (outbuf) { free(outbuf); outbuf = NULL; }
    if (keyRef) CFRelease(keyRef);
    return result;
}


#pragma mark - Base64

@implementation BDDYCSecurity (BBRBASE64)

+ (NSString *)base64Encode:(NSString *)text
{
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    return bdd_base64Encode(data);
}

+ (NSString *)base64Decode:(NSString *)text
{
    NSData *decodeData = bdd_base64Decode(text);
    return [[NSString alloc] initWithData:decodeData encoding:NSUTF8StringEncoding];
}

@end



#pragma mark - MD5

@implementation BDDYCSecurity (MD5)

+ (NSString *)MD5File:(NSString *)filePath
{
    return bdd_MD5File(filePath);
}

+ (NSString *)MD5Data:(id)data
{
    return bdd_MD5Data(data);
}

@end



#pragma mark - Symmetric(AES)

@implementation BDDYCSecurity (Symmetric)

static int bdd_SecRandomCopyBytes(void *rnd, size_t count, uint8_t *bytes)
{
    static int kSecRandomFD;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kSecRandomFD = open("/dev/random", O_RDONLY);
    });
    
    if (kSecRandomFD < 0)
        return -1;
    while (count) {
        ssize_t bytes_read = read(kSecRandomFD, bytes, count);
        if (bytes_read == -1) {
            if (errno == EINTR) continue;
            return -1;
        }
        if (bytes_read == 0) {
            return -1;
        }
        bytes += bytes_read;
        count -= bytes_read;
    }
    
    return 0;
}

+ (NSData *)randomDataOfNumberOfBytes:(size_t)length
{
    NSMutableData *data = [NSMutableData dataWithLength:length];
    
    int result;
    if (&SecRandomCopyBytes != NULL) {
        result = SecRandomCopyBytes(NULL, length, data.mutableBytes);
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
        result = bdd_SecRandomCopyBytes(NULL, length, data.mutableBytes);
#pragma clang diagnostic pop
    }
    NSAssert(result == 0, @"Unable to generate random bytes: %d", errno);
    
    return data;
}

+ (NSData *)randomIVData
{
    return [self.class randomDataOfNumberOfBytes:BDDYC_AES_IV_SIZE];
}

+ (NSData *)randomKeyData
{
    return [self.class randomDataOfNumberOfBytes:BDDYC_AES_KEY_SIZE];
}

+ (NSString *)randomKeyString
{
    NSData *data = [self randomKeyData];
    return bdd_base64Encode(data);
}

+ (NSData *)paddedDataOfKey:(NSString *)keyString
              numberOfBytes:(size_t)numberOfBytes
{
    if (!keyString) {
        return nil;
    }
    NSData *data = [keyString dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length == numberOfBytes) return data;
    if (data.length > numberOfBytes) return [data subdataWithRange:NSMakeRange(0, numberOfBytes)];
    uint8_t *bytePtr = malloc(numberOfBytes);
    bzero(bytePtr, numberOfBytes);
    [data getBytes:bytePtr length:MIN(data.length, numberOfBytes)];
    NSData *byteData = [NSData dataWithBytes:bytePtr length:numberOfBytes];
    if (bytePtr) free(bytePtr);
    return byteData;
}

+ (NSData *)defaultSymmetricKeyData
{
    return [self.class paddedDataOfKey:@"com.dynamically.security.default.key" numberOfBytes:BDDYC_AES_KEY_SIZE];
}

#pragma mark -

+ (NSData *)AESEncryptData:(NSData *)data
                   keyData:(NSData *)keyData
                    ivData:(NSData *)ivData
{
    keyData = keyData ? : [self.class defaultSymmetricKeyData];
    NSData *encryptedData = bdd_AESEncryptData(data, ivData, keyData);
    return encryptedData;
}

+ (NSData *)AESEncryptData:(NSData *)data
                 keyString:(NSString *)privateKey
                  ivString:(NSString *)ivString
{
    NSData *keyData = [self.class paddedDataOfKey:privateKey numberOfBytes:BDDYC_AES_KEY_SIZE] ? : [self.class defaultSymmetricKeyData];
    NSData *ivData  = [self.class paddedDataOfKey:ivString numberOfBytes:BDDYC_AES_IV_SIZE];
    return [self.class AESEncryptData:data keyData:keyData ivData:ivData];
}

+ (NSString *)AESEncryptString:(NSString *)dataText
                     keyString:(NSString *)keyString
                      ivString:(NSString *)ivString
{
    NSData *keyData = [self.class paddedDataOfKey:keyString numberOfBytes:BDDYC_AES_KEY_SIZE] ? : [self.class defaultSymmetricKeyData];
    NSData *ivData  = [self.class paddedDataOfKey:ivString numberOfBytes:BDDYC_AES_IV_SIZE];
    return [self.class AESEncryptString:dataText keyData:keyData ivData:ivData];
}

+ (NSString *)AESEncryptString:(NSString *)dataText
                       keyData:(NSData *)keyData
                        ivData:(NSData *)ivData
{
    NSData *data = [dataText dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [self.class AESEncryptData:data keyData:keyData ivData:ivData];
    NSString *base64Encode = bdd_base64Encode(encryptedData);
    return base64Encode;
}

#pragma mark -

+ (NSData *)AESDecryptData:(NSData *)data
                   keyData:(NSData *)keyData
                    ivData:(NSData *)ivData
{
    keyData = keyData ? : [self.class defaultSymmetricKeyData];
    NSData *decryptedData = bdd_AESDecryptData(data, ivData, keyData);
    return decryptedData;
}

+ (NSData *)AESDecryptData:(NSData *)data
                 keyString:(NSString *)keyString
                  ivString:(NSString *)ivString
{
    NSData *keyData = [self.class paddedDataOfKey:keyString numberOfBytes:BDDYC_AES_KEY_SIZE] ? : [self.class defaultSymmetricKeyData];
    NSData *ivData = [self.class paddedDataOfKey:ivString numberOfBytes:BDDYC_AES_IV_SIZE];
    return [self.class AESDecryptData:data keyData:keyData ivData:ivData];
}

+ (NSString *)AESDecryptString:(NSString *)dataText
                     keyString:(NSString *)keyString
                      ivString:(NSString *)ivString
{
    NSData *keyData = [self.class paddedDataOfKey:keyString numberOfBytes:BDDYC_AES_KEY_SIZE] ? : [self.class defaultSymmetricKeyData];
    NSData *ivData = [self.class paddedDataOfKey:ivString numberOfBytes:BDDYC_AES_IV_SIZE];
    return [self.class AESDecryptString:dataText keyData:keyData ivData:ivData];
}

+ (NSString *)AESDecryptString:(NSString *)dataText
                       keyData:(NSData *)keyData
                        ivData:(NSData *)ivData
{
    NSData *data = bdd_base64Decode(dataText);
    NSData *decryptedData = [self.class AESDecryptData:data keyData:keyData ivData:ivData];
    NSString *decryptedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    return decryptedString;
}

@end



#pragma mark - Asymmetric(RSA)

@implementation BDDYCSecurity (Asymmetric)
// 返回base64编码的字符串
+ (NSString *)RSAEncryptString:(NSString *)str
                     publicKey:(NSString *)pubKey
{
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [self.class RSAEncryptData:data publicKey:pubKey];
    NSString *base64Encode = bdd_base64Encode(encryptedData);
    return base64Encode;
}

+ (NSData *)RSAEncryptData:(NSData *)data
                 publicKey:(NSString *)pubKey
{
    return bdd_RSAEncryptData(data, pubKey);
}

+ (NSString *)RSADecryptString:(NSString *)str
                     publicKey:(NSString *)pubKey
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self.class RSADecryptData:data publicKey:pubKey];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return ret;
}

+ (NSData *)RSADecryptData:(NSData *)data
                 publicKey:(NSString *)pubKey
{
    return bdd_RSADecryptData(data, pubKey);
}

@end

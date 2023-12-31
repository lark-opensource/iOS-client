//
//  RtcCryptor.m
//  ByteView
//
//  Created by ZhangJi on 2023/5/11.
//

#import "E2eeRtcCryptor.h"

@interface E2eeRtcCryptor ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *encryptErrors;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *decryptErrors;
@property (nonatomic) ResourceEncryptAlgorithm algorithm;
@property (nonatomic, copy) NSData *key;

@end

@implementation E2eeRtcCryptor

- (instancetype)initWithAlgorithm:(ResourceEncryptAlgorithm)algorithm key:(NSData *)key {
    if (self = [super init]) {
        self.encryptErrors = [[NSMutableDictionary alloc] init];
        self.decryptErrors = [[NSMutableDictionary alloc] init];
        self.algorithm = algorithm;
        self.key = key;
    }
    return self;
}

- (unsigned int)encrypt:(const unsigned char *)data length:(unsigned int)length buf:(unsigned char *)buf buf_len:(unsigned int)buf_len {
    if (length == 0) {
        [self setError:-1 to:self.encryptErrors];
        NSLog(@"on encrypt data failed reason: data length is zero");
        return 0;
    }
    size_t outputLength = buf_len;
    ResourceEncryptResult result = lark_sdk_resource_encrypt_aead_seal(self.algorithm, (const uint8_t *)self.key.bytes, (size_t)self.key.length, data, length, buf, &outputLength);
    if (result != ResourceEncryptResult::OK) {
        [self setError:(int)result to:self.encryptErrors];
        NSLog(@"on encrypt data failed %d", result);
        return 0;
    }
    return (unsigned int)outputLength;
}

- (unsigned int)decrypt:(const unsigned char *)data length:(unsigned int)length buf:(unsigned char *)buf buf_len:(unsigned int)buf_len {
    if (length == 0) {
        [self setError:-1 to:self.decryptErrors];
        NSLog(@"on decrypt data failed reason: data length is zero");
        return 0;
    }
    size_t outputLength = buf_len;
    ResourceEncryptResult result = lark_sdk_resource_encrypt_aead_open(self.algorithm, (const uint8_t *)self.key.bytes, (size_t)self.key.length, data, length, buf, &outputLength);
    if (result != ResourceEncryptResult::OK) {
        [self setError:(int)result to:self.decryptErrors];
        NSLog(@"on decrypt data failed %d", result);
        return 0;
    }
    return (unsigned int)outputLength;
}

- (void)setError:(int)code to:(NSMutableDictionary<NSNumber *, NSNumber *> *)errors {
    NSNumber *codeObj = [NSNumber numberWithInt:code];
    if (NSNumber *count = errors[codeObj]) {
        errors[codeObj] = [NSNumber numberWithInt:count.intValue + 1];
    } else {
        errors[codeObj] = [NSNumber numberWithInt:1];
    }
}

@end

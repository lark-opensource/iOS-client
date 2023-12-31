//
//  BDAutoTrackEncryptorSM2.m
//  GMObjC-framework
//
//  Created by bytedance on 2023/3/2.
//

#import "BDAutoTrackEncryptorSM2.h"
#import "GMSm2Utils.h"
#import "GMUtils.h"


@interface BDAutoTrackEncryptorSM2()

@end

@implementation BDAutoTrackEncryptorSM2

static NSString *_publicKey;

+ (void)setPublickKey:(NSString *)publicKey {
    _publicKey = publicKey;
}

+ (NSString *)publicKey {
    return _publicKey;
}

- (NSData *)encryptData:(NSData *)data error:(NSError * __autoreleasing *)error {
    NSData *encryptedData = [GMSm2Utils encryptData:data publicKey:_publicKey];
    encryptedData = [GMSm2Utils asn1DecodeToC1C3C2Data:encryptedData];
    
    NSMutableData *sendData = [NSMutableData dataWithData:[GMUtils hexToData:@"04"]];
    [sendData appendData:encryptedData];
    
    return sendData;
}


@end

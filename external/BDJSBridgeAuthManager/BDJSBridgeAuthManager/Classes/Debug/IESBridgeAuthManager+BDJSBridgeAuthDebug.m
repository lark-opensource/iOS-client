//
//  IESBridgeAuthManager+BDJSBridgeAuthDebug.m
//  BDJSBridgeAuthManager-CN-Core
//
//  Created by bytedance on 2020/8/26.
//

#import "IESBridgeAuthManager+BDJSBridgeAuthDebug.h"
#import "TTNetworkManager+IESWKAddition.h"
#import <ByteDanceKit/BTDMacros.h>
#import <Godzippa/NSData+Godzippa.h>

@implementation IESBridgeAuthManager (BDPiperAuthDebug)

+ (void)fetchAuthInfosWithCompletion:(IESBridgeAuthJSONFinishBlock)completion{
    NSString *authDomain = self.requestParams.authDomain;
    NSString *accessKey = self.requestParams.accessKey;
    NSDictionary *commonParams = self.requestParams.commonParams ? self.requestParams.commonParams() : nil;
    NSArray<NSString *> *extraChannels = self.requestParams.extraChannels ? self.requestParams.extraChannels : nil;
    
    if (BTD_isEmptyString(authDomain) || BTD_isEmptyString(accessKey) || !commonParams) {
        NSError *error = [NSError errorWithDomain:@"configuration error" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"IESBridgeAuthManager configuration error."}];
        completion(error, nil);
        return;
    }
    NSDictionary *requestParams = [self getRequestParamsWithAccessKey:accessKey commonParams:commonParams extraChannels:extraChannels];
    NSString *requestURL = [NSString stringWithFormat:@"https://%@/src/server/v2/package", authDomain];

    [TTNetworkManager.shareInstance requestWithURL:requestURL method:@"POST" params:requestParams callback:^(NSError *error, id jsonObj) {
        completion(error, jsonObj);
    }];
}
+ (void)getBuiltInAuthInfosWithCompletion:(IESBridgeAuthJSONFinishBlock)completion{
    NSError *error = nil;
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"jsb_auth_infos" withExtension:@"json.gz"];
    NSData *compressedData = [NSData dataWithContentsOfURL:fileURL];
    NSData *uncompressedData = [compressedData dataByGZipDecompressingDataWithError:&error];
    NSDictionary *json = nil;
    if (uncompressedData && !error) {
        json = [NSJSONSerialization JSONObjectWithData:uncompressedData options:kNilOptions error:&error];
    }
    completion(error,json);
}



@end

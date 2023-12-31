#import "IESGurdEncrypt.h"
#import <CommonCrypto/CommonDigest.h>

#define SALT @"rhJ9jOgHXVe1yRkAed2ExkyFaMPDHweCOAay7J/AlSwq4FH0WMC1ovlmPCGPo4pOW69SrLZyLoriJXW2WYPyU7r+nLRIc8GHOa+cFmLSIzDM2gvzrM7QQtpI3k9iFLCPsMN4RAzrDQozCUT2ZIv7XRZjEGADBS48qdMH92QTLKo="
#define MD5_LENGTH 16

@protocol IESGurdResourceManagerProtocol <NSObject>
+ (void)realRequestWithMethod:(NSString * _Nonnull)method
                    URLString:(NSString * _Nonnull)URLString
                       params:(NSDictionary * _Nullable)params
                   completion:(IESGurdHTTPRequestCompletion)completion;
@end

static NSString *md5WithString(NSString *str)
{
    const char* originalStr = [str UTF8String];
    unsigned char digist[MD5_LENGTH];
    CC_MD5(originalStr, (uint)strlen(originalStr), digist);
    NSMutableString* outStr = [NSMutableString stringWithCapacity:MD5_LENGTH];
    for(int i = 0; i < MD5_LENGTH; i++){
        [outStr appendFormat:@"%02x", digist[i]];
    }
    return [outStr lowercaseString];
}

void IESGurdEncryptRequest(NSString *method, NSString *URLString, NSMutableDictionary *params, IESGurdHTTPRequestCompletion completion)
{
    NSMutableDictionary *auth = [NSMutableDictionary dictionary];
    u_int64_t time = (u_int64_t)([[NSDate date] timeIntervalSince1970]);
    auth[@"random"] = [NSString stringWithFormat:@"%lld", time];
    auth[@"sign"] = [NSString stringWithFormat:@"x_gecko_sign_placeholder_%@", auth[@"random"]];
    params[@"auth"] = auth;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:NULL];
    NSString *jsonStr = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *encryptStr = [NSString stringWithFormat:@"%@%@%@", jsonStr, auth[@"random"], SALT];
    NSString *sign = md5WithString(encryptStr);
    auth[@"sign"] = sign;
    
    Class<IESGurdResourceManagerProtocol> resourceManager = NSClassFromString(@"IESGurdResourceManager");
    [resourceManager realRequestWithMethod:method URLString:URLString params:[params copy] completion:completion];
}

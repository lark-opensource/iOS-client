//
//  BDPUtils.m
//  ECOInfra
//
//  Created by Meng on 2021/3/25.
//

#import "BDPUtils.h"
#import "JSONValue+BDPExtension.h"
#import "NSDictionary+BDPExtension.h"

#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <ECOInfra/ECOInfra-Swift.h>

NSString *const BDPErrorDomain = @"BDPErrorDomain";

BOOL BDPIsMainQueue(void)
{
    return [[NSThread currentThread] isMainThread];
}

BOOL BDPRunningInAppExtension(void)
{
    return [[[[NSBundle mainBundle] bundlePath] pathExtension] isEqualToString:@"appex"];
}

UIApplication *__nullable BDPSharedApplication(void)
{
    if (BDPRunningInAppExtension()) {
        return nil;
    }
    return [[UIApplication class] performSelector:@selector(sharedApplication)];
}

NSError *BDPErrorWithMessage(NSString *message)
{
    return BDPErrorWithMessageAndCode(message, 0);
}

NSError *BDPErrorWithMessageAndCode(NSString *message, NSInteger code)
{
    return BDPErrorWithMessageAndCodeAndDomain(message, code, BDPErrorDomain);
}

NSError *BDPErrorWithMessageAndCodeAndDomain(NSString *message, NSInteger code, NSString *domain)
{
    if (!BDPIsEmptyString(domain)) {
        NSDictionary<NSString *, id> *errorInfo = @{NSLocalizedDescriptionKey:BDPSafeString(message)};
        return [[NSError alloc] initWithDomain:domain code:code userInfo:errorInfo];
    }
    return nil;
}

NSError *BDPErrorWithResponse(id responseData, NSError *error)
{
    if (error) return error;

    NSDictionary *response = responseData;
    if ([responseData isKindOfClass:[NSData class]]) {
        response = [responseData JSONValue];
    }

    NSInteger errorCode = 0;
    if ([response objectForKey:@"error"]) {
        errorCode = [response[@"error"] integerValue];
    } else if ([response objectForKey:@"err_no"]) {
        errorCode = [response[@"err_no"] integerValue];
    }
    if (errorCode != 0) {
        NSString *message = BDPSafeString(response[@"message"]);
        return BDPErrorWithMessageAndCode(message, errorCode);
    }
    return nil;
}

NSInteger BDPHostAppId(void)
{
    return [[[NSBundle mainBundle] infoDictionary] bdp_integerValueForKey:@"SSAppID"];
}

void BDPSaveImageToPhotosAlbum(NSString *tokenIdentifier, NSData *imageData, void(^completion)(BOOL success, NSError *_Nullable error))
{
    // Null Image Data
    if (!imageData || ![imageData isKindOfClass:[NSData class]]) {
        if (completion) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"imageData is invalid"};
            completion(NO, [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo]);
        }
        return;
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        NSError *error;
        NSString *token = tokenIdentifier == nil ? @"" :tokenIdentifier;
        PHAssetCreationRequest *request = [LarkSensitivityControlAdapter photos_PHAssetCreationRequest_creationRequestForAssetWithTokenIdentifier:token error:&error];
        if(request != nil) {
            [request addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
        } else {
            completion(false, error);
        }
    } completionHandler:completion];
}

void BDPSaveVideoToPhotosAlbum(NSString *tokenIdentifier, NSURL *fileURL, void(^completion)(BOOL success, NSError *_Nullable error))
{
    // Null Image Data
    if (!fileURL || ![fileURL isKindOfClass:[NSURL class]]) {
        if (completion) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"fileURL is invalid"};
            completion(NO, [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo]);
        }
        return;
    }

    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        NSError *error;
        NSString *token = tokenIdentifier == nil ? @"" :tokenIdentifier;
        PHAssetCreationRequest *request = [LarkSensitivityControlAdapter photos_PHAssetCreationRequest_creationRequestForAssetWithTokenIdentifier:token error:&error];
        if(request != nil) {
            [request addResourceWithType:PHAssetResourceTypeVideo fileURL:fileURL options:nil];
        } else {
            completion(false, error);
        }
    } completionHandler:completion];
}

NSString *BDPRandomString(NSInteger length)
{
    if (length <= 0) return @"";

    NSString *alphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    for (int i = 0; i < length; i++) {
        [randomString appendFormat: @"%C", [alphabet characterAtIndex:arc4random_uniform((int)[alphabet length])]];
    }
    return randomString;
}

NSString *BDPMIMETypeOfFilePath(NSString *filePath)
{
    NSString *type = @"application/octet-stream";
    if (!BDPIsEmptyString(filePath.pathExtension)) {
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)filePath.pathExtension, NULL);
        if (UTI) {
            CFStringRef mType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
            CFRelease(UTI);
            if (mType) {
                type = (__bridge_transfer NSString *)mType;
            }
        }
    }
    return type;
}

NSString *BDPSystemVersion(void)
{
    NSOperatingSystemVersion sysVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    return [NSString stringWithFormat:@"%ld.%ld.%ld", (long)sysVersion.majorVersion, (long)sysVersion.minorVersion, (long)sysVersion.patchVersion];
}

BOOL BDPIsEmptyArray(NSArray *array)
{
    return (!array || ![array isKindOfClass:[NSArray class]] || array.count == 0);
}

BOOL BDPIsEmptyString(NSString *string)
{
    return (!string || ![string isKindOfClass:[NSString class]] || string.length == 0);
}


BOOL BDPIsEmptyDictionary(NSDictionary *dict)
{
    return (!dict || ![dict isKindOfClass:[NSDictionary class]] || ((NSDictionary *)dict).count == 0);
}

NSArray *BDPSafeArray(NSArray *array)
{
    return [array isKindOfClass:[NSArray class]] ? array :@[];
}

NSString *BDPSafeString(NSString *string)
{
    return [string isKindOfClass:[NSString class]] ? string : @"";
}

NSDictionary *BDPSafeDictionary(NSDictionary *dict)
{
    return [dict isKindOfClass:[NSDictionary class]] ? dict : @{};
}



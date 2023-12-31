//
//  TTVideoEngineUtil.m
//  Pods
//
//  Created by guikunzhi on 16/12/6.
//
//

#import "TTVideoEngineUtil.h"
#import "TTVideoEnginePlayerDefinePrivate.h"
#include <TTPlayerSDK/av_error.h>
#include <sys/stat.h>
#include <sys/mount.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <TTPlayerSDK/ttvideodec.h>


NS_PLAYER_BEGIN

BOOL isNetworkError(NSInteger code) {
    if (code == AVError::SETTING_URI_IS_NULL_ERROR || code == AVError::SETTING_URI_IS_ERROR ||
        code == AVError::URL_IS_NOT_MP4 || code == AVError::INVALID_INPUT_DATA ||
        code == AVError::HTTP_BAD_REQUEST || code == AVError::HTTP_UNAUTHORIZED ||
        code == AVError::HTTP_FORBIDEN || code == AVError::HTTP_NOT_FOUND ||
        code == AVError::HTTP_OTHER_4xx || code == AVError::HTTP_SERVER_ERROR ||
        code == AVError::HTTP_CONTENT_TYPE_IS_INVALID || code == AVError::HTTP_REDIRECT ||
        code == AVError::TCP_FAILED_TO_RESOLVE_HOSTNAME || code == AVError::TCP_FAILED_TO_SETUP_SOCKET ||
        code == AVError::TCP_CONNECT_FAILED || code == AVError::TCP_SEND_DATA_FAILED ||
        code == AVError::TCP_RECEIVE_DATA_FAILED || code == AVError::TCP_READ_NETWORK_TIMEOUT ||
        code == AVError::TCP_WRITE_NETWORK_TIMEOUT || code == -59990 || code == -59989) {
        return YES;
    }
    return NO;
}

BOOL isHijackError(NSInteger code) {
    if (code == AVError::HIJACK_VID_ERROR ||
        code == AVError::HIJACK_MEDIA_TYPE_ERROR) {
        return YES;
    }
    return NO;
}

BOOL isDrmError(NSInteger code) {
    if (code == AVError::DRM_OPEN_FAILED ||
        code == AVError::DRM_DECRYPT_FAILED) {
        return YES;
    }
    return NO;
}

BOOL needRestartPlayer(NSInteger code) {
    if (code == AVError::SETTING_IS_NULL_ERROR || code == AVError::START_DECODER_ERROR ||
        code == AVError::OPEN_DECODER_ERROR || code == AVError::OPEN_OUTLET_ERROR ||
        code == AVError::START_OUTPUTER_ERROR || code == AVError::START_OUTLET_ERROR ||
        code == AVError::OPEN_DEVICE_ERROR) {
        return YES;
    }
    return NO;
}

BOOL isDataError(NSInteger code) {
    if (code == AVError::INVALID_INPUT_DATA ||
        code == AVError::AUDIO_DECODER_WRITE_ERROR ||
        code == AVError::VIDEO_DECODER_WRITE_ERROR ||
        code == -1094995529) {
        return YES;
    }
    return NO;
}

NS_PLAYER_END

NSString *const TTVideoEngineBufferStartAction = @"_TTVideoEngineBufferStartAction";
NSString *const TTVideoEngineBufferStartReason = @"_TTVideoEngineBufferStartReason";

BOOL TTVideoEngineIsNetworkError(NSInteger code) {
    return com::ss::ttm::player::isNetworkError(code);
}

BOOL TTVideoEngineIsHijackError(NSInteger code) {
    return com::ss::ttm::player::isHijackError(code);
}

BOOL TTVideoEngineIsDrmError(NSInteger code) {
    return com::ss::ttm::player::isDrmError(code);
}

BOOL TTVideoEngineNeedRestartPlayer(NSInteger code) {
    return com::ss::ttm::player::needRestartPlayer(code);
}

BOOL TTVideoEngineIsDataError(NSInteger code) {
    return com::ss::ttm::player::isDataError(code);
}

TTVideoEngineRetryStrategy TTVideoEngineGetStrategyFrom(NSError *error, NSInteger playerUrlDNSRetryCount) {
    if ([error.domain isEqualToString:kTTVideoErrorDomainHTTPDNS] || [error.domain isEqualToString:kTTVideoErrorDomainLocalDNS]) {
        return TTVideoEngineRetryStrategyChangeURL;
    }
    if ([error.domain isEqualToString:kTTVideoErrorDomainFetchingInfo]) {
        return TTVideoEngineRetryStrategyFetchInfo;
    }
    if ([error.domain isEqualToString:kTTVideoErrorDomainOwnPlayer]) {
        if (TTVideoEngineIsNetworkError(error.code)) {
            return TTVideoEngineRetryStrategyChangeURL;
        }
        if (TTVideoEngineNeedRestartPlayer(error.code)) {
            return TTVideoEngineRetryStrategyRestartPlayer;
        }
    }
    return TTVideoEngineRetryStrategyChangeURL;
}

TTVideoEnigneErrorType TTVideoEngineGetErrorType(NSError *error) {
    if ([error.domain isEqualToString:kTTVideoErrorDomainFetchingInfo]) {
        return TTVideoEngineErrorTypeAPI;
    }
    if ([error.domain isEqualToString:kTTVideoErrorDomainLocalDNS] || [error.domain isEqualToString:kTTVideoErrorDomainHTTPDNS] || [error.domain isEqualToString:kTTVideoErrorDomainCacheDNS]) {
        return TTVideoEngineErrorTypeDNS;
    }
    if ([error.domain isEqualToString:kTTVideoErrorDomainOwnPlayer] && TTVideoEngineNeedRestartPlayer(error.code)) {
        return TTVideoEngineErrorTypePlayer;
    }
    return TTVideoEngineErrorTypeCDN;
}

NSString *TTVideoEngineBuildHttpsUrl(NSString *url)
{
    if (url == nil) {
        return nil;
    }
    if (![url containsString:@"127.0.0.1"]) {
        url = [url stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    }
    return url;
}

BOOL TTVideoEngineIsHexString(NSString* str) {
    if (str == nil || ![str isKindOfClass:[NSString class]] || [str length] <= 0) {
        return NO;
    }
    
    NSString *hexRegx =@"^[A-Fa-f0-9]+$";
    NSPredicate *isHexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", hexRegx];
    BOOL isHex = [isHexPredicate evaluateWithObject:str];
    
    return isHex;
}

BOOL TTVideoEngineIsTranscodeUrl(NSString* str) {
    if (str == nil || ![str isKindOfClass:[NSString class]] || [str length] <= 0) {
        return NO;
    }
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:str];
    NSString *btagValue = nil;
    for (NSURLQueryItem* item in [urlComponents queryItems]) {
        if ([[item name] isEqual:@"btag"]) {
            btagValue = [item value];
            break;
        }
    }
    
    if (btagValue == nil) {
        return NO;
    }
    
    if (!TTVideoEngineIsHexString(btagValue)) {
        return NO;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:btagValue];
    unsigned long long hexValue = 0;
    BOOL didParse = [scanner scanHexLongLong:&hexValue];
    
    if (!didParse) {
        return NO;
    }
    
    unsigned long long transcode = 2 << 18;
    
    if ((hexValue & transcode) == transcode) {
        return YES;
    }
    
    return NO;
}

BOOL TTVideoEngineIsTranscodeUrls(NSArray *arr) {
    if (arr == nil || ![arr isKindOfClass:[NSArray class]] || arr.count == 0) {
        return NO;
    }
    
    for (int i = 0; i < [arr count]; ++i) {
        if (TTVideoEngineIsTranscodeUrl(arr[i])) {
            return YES;
        }
    }
    
    return NO;
}

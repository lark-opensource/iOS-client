//
//  BDAutoTrackNetworkRequest.m
//  RangersAppLog
//
//  Created by bob on 2019/9/13.
//

#import "BDAutoTrackNetworkRequest.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackParamters.h"

#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackRegisterService.h"

#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrack.h"
#import "BDAutoTrackURLHostProvider.h"

NSMutableDictionary * bd_requestURLParameters(NSString *appID) {
    NSMutableDictionary *result = [NSMutableDictionary new];
    bd_addQueryNetworkParams(result, appID);

    return result;
}

NSString * bd_validateRequestURL(NSString *requestURL) {
    if (![requestURL isKindOfClass:[NSString class]] || requestURL.length < 1) {
        return nil;
    }

    requestURL = [requestURL stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    requestURL = [requestURL stringByAddingPercentEncodingWithAllowedCharacters:bd_URLAllowedCharacters()];

    if (requestURL.length < 1 || ![NSURL URLWithString:requestURL]) {
        return nil;
    }

    if (![requestURL hasSuffix:@"/"]) {
        requestURL = [requestURL stringByAppendingString:@"/"];
    }

    return requestURL;
}


NSMutableDictionary * bd_requestPostHeaderParameters(NSString *appID) {
    NSMutableDictionary *result = [NSMutableDictionary new];
    bd_addBodyNetworkParams(result, appID);
    bd_addSettingParameters(result, appID);
    bd_registeredAddParameters(result, appID);

    return result;
}


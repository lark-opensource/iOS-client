//
//  BDAutoTrackParamters.h
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrack.h"
#import "BDAutoTrackEncryptionDelegate.h"

#ifndef BDAutoTrackParameters_H
#define BDAutoTrackParameters_H

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *bd_appendQueryDictToURL(NSString *url, NSDictionary *queries);
FOUNDATION_EXPORT NSString *bd_appendQueryToURL(NSString *url, NSString *key, NSString *value);
FOUNDATION_EXPORT NSString *bd_appendQueryStringToURL(NSString *url, NSString *pairs);

/* Network Params */
FOUNDATION_EXTERN NSMutableDictionary * bd_headerField(NSString *appID);
FOUNDATION_EXTERN void bd_addQueryNetworkParams(NSMutableDictionary *result, NSString *appID);
FOUNDATION_EXTERN void bd_addBodyNetworkParams(NSMutableDictionary *result, NSString *appID);

/* Event Params */
FOUNDATION_EXTERN void bd_addSharedEventParams(NSMutableDictionary *result, NSString *appID);
FOUNDATION_EXTERN void bd_addEventParameters(NSMutableDictionary * result);
FOUNDATION_EXTERN void bd_addABVersions(NSMutableDictionary *result, NSString *appID);

FOUNDATION_EXTERN void bd_addScreenOrientation(NSMutableDictionary *result, NSString *appID);
FOUNDATION_EXTERN void bd_addGPSLocation(NSMutableDictionary *result, NSString *appID);

FOUNDATION_EXTERN void bd_addAppVersion(NSMutableDictionary *result);

FOUNDATION_EXTERN BOOL bd_isValidResponse(NSDictionary * _Nullable responseDict);
FOUNDATION_EXTERN BOOL bd_isResponseMessageSuccess(NSDictionary * _Nullable responseDict);

FOUNDATION_EXTERN NSDictionary* bd_filterSensitiveParameters(NSDictionary *body, NSString *appID);
FOUNDATION_EXTERN void bd_handleCommonParamters(NSDictionary *body, BDAutoTrack *tracker, BDAutoTrackRequestURLType requestURLType);


NS_ASSUME_NONNULL_END

#endif

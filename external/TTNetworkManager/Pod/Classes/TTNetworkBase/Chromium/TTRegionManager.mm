//
//  TTRegionManager.m
//  TTNetworkManager
//
//  Created by bytedance on 2021/6/30.
//

#import "TTRegionManager.h"

#import <Foundation/Foundation.h>
#import "TTNetworkManager.h"
#import "TTNetworkUtil.h"
#import "TTNetworkManagerChromium.h"
#import "TTNetworkManagerLog.h"

#include "base/strings/sys_string_conversions.h"
#ifndef OC_DISABLE_STORE_IDC
#include "net/tt_net/tt_region/store_idc_manager.h"
#endif

@implementation TTRegionManager

+ (NSString *) getdomainRegionConfig {
    NSDictionary<NSString *, NSString *> *getDomainRegionConfig = [TTNetworkManager shareInstance].getDomainRegionConfig;
    if (!getDomainRegionConfig || [getDomainRegionConfig allKeys].count <= 0) {
        return [TTNetworkManager shareInstance].getDomainDefaultJSON;
    }

    NSDictionary<NSString *, NSString *> *commonParamValue = [TTNetworkManagerChromium shareInstance].commonParamsblock();
    NSString* region = [commonParamValue objectForKey:@"region"];
    NSString* sysRegion = [commonParamValue objectForKey:@"sys_region"];
    NSString* carrierRegion = [commonParamValue objectForKey:@"carrier_region"];
    NSString* getDomainConfig;
    if (carrierRegion) {
        getDomainConfig = [getDomainRegionConfig objectForKey:[carrierRegion lowercaseString]];
    } else if (sysRegion) {
        getDomainConfig = [getDomainRegionConfig objectForKey:[sysRegion lowercaseString]];
    } else if (region) {
        getDomainConfig = [getDomainRegionConfig objectForKey:[region lowercaseString]];
    }

    if (!getDomainConfig) {
        getDomainConfig = [TTNetworkManager shareInstance].getDomainDefaultJSON;
    }

    return getDomainConfig;
}

#ifndef OC_DISABLE_STORE_IDC
+(std::pair<std::string, std::string>)extractStoreRegionFromCookieHeaders:(const net::HttpResponseHeaders*) headers {
    std::pair<std::string, std::string> pair;
    if (!headers) return pair;
    std::string storeRegionCookie = kStoreCountryCodeCookie;
    std::string storeRegionSrcCookie = kStoreCountryCodeSrcCookie;
    if ([[TTNetworkManager shareInstance] useDomesticStoreRegion]) {
        storeRegionCookie = kStoreRegionCookie;
        storeRegionSrcCookie = kStoreRegionSrcCookie;
    }
    
    // Parse and save cookie header which is "Set-Cookie:store-country-code=xxx; xxx=xxx; xxx=xxx".
    const base::StringPiece name("Set-Cookie");
    std::string storeCountryCode;
    std::string storeCountryCodeSrc;
    std::string cookieString;
    size_t iter = 0;
    while (headers->EnumerateHeader(&iter, name, &cookieString)) {
        base::TrimString(cookieString, " ", &cookieString);
        base::StringPiece cookie(cookieString);
        if (base::StartsWith(cookie, storeRegionCookie, base::CompareCase::INSENSITIVE_ASCII)) {
            storeCountryCode = cookieString;
            continue;
        }
        
        if (base::StartsWith(cookie, storeRegionSrcCookie, base::CompareCase::INSENSITIVE_ASCII)) {
            storeCountryCodeSrc = cookieString;
            continue;
        }
    }
    
    if (storeCountryCode.empty()) {
        return pair;
    }

    std::string storeRegion;
    std::vector<std::string> part1 = base::SplitString(storeCountryCode, ";", base::TRIM_WHITESPACE, base::SPLIT_WANT_NONEMPTY);
    if (part1.size() > 0) {
        storeCountryCode = part1[0];
        std::vector<std::string> part2 = base::SplitString(storeCountryCode, "=", base::TRIM_WHITESPACE, base::SPLIT_WANT_NONEMPTY);
        if (part2.size() == 2) {
            storeRegion = part2[1];
        }
    }
    
    std::string storeRegionSrc;
    if (!storeCountryCodeSrc.empty()) {
        std::vector<std::string> part3 = base::SplitString(storeCountryCodeSrc, ";", base::TRIM_WHITESPACE, base::SPLIT_WANT_NONEMPTY);
        if (part3.size() > 0) {
            storeCountryCodeSrc = part3[0];
            std::vector<std::string> part4 = base::SplitString(storeCountryCodeSrc, "=", base::TRIM_WHITESPACE, base::SPLIT_WANT_NONEMPTY);
            if (part4.size() == 2) {
                storeRegionSrc = part4[1];
            }
        }
    }
    
    if (storeRegion.empty()) {
        return pair;
    }
    
    pair.first = storeRegion;
    pair.second = storeRegionSrc;
    return pair;
}

+(void)updateStoreRegionConfigFromResponse:(const net::URLFetcher*)response responseBody:(NSData *)responseBody url:(NSURL *)url {
    auto* manager = net::StoreIdcManager::GetInstance();
    if (!manager->IsStoreRegionEnabled() || !response || response->GetResponseCode() != 200 || !response->GetResponseHeaders() || !url) {
        return;
    }

    NSString *realPath = [TTNetworkUtil.class getRealPath:url];
    NSMutableArray *pathFilterArray = [[NSMutableArray alloc] init];
    for (const auto& path : manager->GetStoreIdcPathList()) {
        [pathFilterArray addObject:[NSString stringWithUTF8String:path.c_str()]];
    }

    if (![TTNetworkUtil.class isMatching:realPath pattern:kCommonMatch source:pathFilterArray]) {
        return;
    }
    const auto& headers = response->GetResponseHeaders();
    const auto& regionPair = [TTRegionManager extractStoreRegionFromCookieHeaders:headers];
    std::string storeRegion = regionPair.first;
    std::string storeSrc = regionPair.second;
    LOGD(@"storeRegion: %@, storeSrc: %@", [NSString stringWithUTF8String:storeRegion.c_str()], [NSString stringWithUTF8String:storeSrc.c_str()]);
    std::string withTncData;
    headers->GetNormalizedHeader("x-tt-with-tnc", &withTncData);
    NSString* data;
    TICK;
    if (withTncData == "1" && responseBody) {
        NSError *jsonError = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseBody options:kNilOptions error:&jsonError];
        if (jsonError == nil) {
            NSDictionary *tempData = [jsonDict objectForKey:@"tnc_data"];
            if (tempData) {
                NSDictionary *tncDataDict = [NSDictionary dictionaryWithObject:tempData forKey:@"data"];
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tncDataDict options:kNilOptions error:&jsonError];
                if (jsonError == nil) {
                    data = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
                } else {
                    LOGD(@"json serialization failed, %@", jsonError);
                }
            }
        } else {
            LOGD(@"json serialization failed, %@", jsonError);
        }
    }
    TOCK;
    
    if (storeRegion.empty() && !data) {
        LOGD(@"storeRegion and data is empty.");
        return;
    }
    
    std::string tncAttr;
    headers->GetNormalizedHeader("x-tt-tnc-attr", &tncAttr);
    std::string tncEtag;
    headers->GetNormalizedHeader("x-ss-etag", &tncEtag);
    std::string tncConfig;
    headers->GetNormalizedHeader("x-tt-tnc-config", &tncConfig);
    NSString *baseLog = url.absoluteString;
    std::string secUid;
    headers->GetNormalizedHeader("x-tt-store-sec-uid", &secUid);
    std::string logid;
    headers->GetNormalizedHeader("x-tt-logid", &logid);
    net::StoreIdcManager::GetInstance()->UpdateStoreRegionFromServer(base::SysNSStringToUTF8(realPath), storeRegion, storeSrc, tncAttr, tncEtag, tncConfig, base::SysNSStringToUTF8(data), base::SysNSStringToUTF8(baseLog), secUid, logid);
}
#endif


@end

//
//  BDTuringUtility.m
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import "BDTuringUtility.h"
#import "BDTuringDefine.h"
#import "BDTuringCoreConstant.h"

long long turing_currentIntervalMS() {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

static NSCharacterSet *turing_URLQueryAllowedCharacterSet() {
    static NSCharacterSet *turing_set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *set = [NSMutableCharacterSet new];
        [set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        [set addCharactersInString:@"$-_.+!*'(),"];
        turing_set = set;
    });

    return turing_set;
}

NSString * turing_queryFromDictionary(NSDictionary *params) {
    if (params.count < 1) {
        return nil;
    }

    NSMutableArray *keyValuePairs = [NSMutableArray array];
    for (id key in params) {
        NSString *queryKey = [[key description] stringByAddingPercentEncodingWithAllowedCharacters:turing_URLQueryAllowedCharacterSet()];
        NSString *queryValue = [[params[key] description] stringByAddingPercentEncodingWithAllowedCharacters:turing_URLQueryAllowedCharacterSet()];

        [keyValuePairs addObject:[NSString stringWithFormat:@"%@=%@", queryKey, queryValue]];
    }

    return [keyValuePairs componentsJoinedByString:@"&"];
}

NSString * turing_requestURLWithQuery(NSString *requestURL, NSDictionary *query) {
    NSString *queryString = turing_queryFromDictionary(query);
    if (queryString.length > 0) {
        if ([requestURL containsString:@"?"]) {
            requestURL = [requestURL stringByAppendingFormat:@"&%@",queryString];
        } else {
            requestURL = [requestURL stringByAppendingFormat:@"?%@",queryString];
        }
    }

    return requestURL;
}

NSString * turing_requestURLWithPath(NSString *requestURL, NSString *path) {
    if ([requestURL hasSuffix:@"/"]) {
        requestURL = [requestURL stringByAppendingFormat:@"%@",path];
    } else {
        requestURL = [requestURL stringByAppendingFormat:@"/%@",path];
    }

    return requestURL;
}

NSString * turing_sandBoxDocumentsPath() {
    static NSString *documentsPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsPath = [dirs objectAtIndex:0];
    });
    
    return documentsPath;
}

NSString * turing_sdkDocumentPath() {
    static NSString *sdkDocumentPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sdkDocumentPath = [turing_sandBoxDocumentsPath() stringByAppendingPathComponent:@"bd.turing"];

        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:sdkDocumentPath isDirectory:&isDir]) {
            if (!isDir) {
                [fm removeItemAtPath:sdkDocumentPath error:nil];
                [fm createDirectoryAtPath:sdkDocumentPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        } else {
            [fm createDirectoryAtPath:sdkDocumentPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        dispatch_block_t block = ^{
            NSURL *url = [NSURL fileURLWithPath:sdkDocumentPath];
            [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        };
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       block);
    });

    return sdkDocumentPath;
}

NSString * turing_sdkDocumentPathForAppID(NSString *appID) {
    NSString *document = turing_sdkDocumentPath();
    NSString *path = [document stringByAppendingPathComponent:appID];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:path isDirectory:&isDir]) {
        if (!isDir) {
            [fm removeItemAtPath:path error:nil];
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
    } else {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return path;
}

NSString * turing_sdkDatabaseFile() {
    return [turing_sdkDocumentPath() stringByAppendingPathComponent:@"bd_turing_v1.sqlite"];
}

NSBundle *turing_sdkBundle() {
    static NSBundle *sdkBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"BDTuringResource" withExtension:@"bundle"];
        sdkBundle = [NSBundle bundleWithURL:url];
    });

    return sdkBundle;
}

static NSString *turing_supportLocaleForLocale(NSString *localeIdentifier) {
    if (localeIdentifier == nil || localeIdentifier.length < 1) {
        return @"en";
    }
    if ([localeIdentifier.lowercaseString isEqualToString:@"zh-hant"]) {
        return @"zh-Hant";
    }
    if ([localeIdentifier.lowercaseString hasPrefix:@"zh"]) {
        return @"zh";
    }
    
    return @"en";
}

NSString *turing_LocalizedString(NSString *key, NSString *localeIdentifier) {
    static dispatch_once_t onceToken;
    static NSMutableDictionary<NSString*, NSBundle *> *languageBundles = nil;
    dispatch_once(&onceToken, ^{
        languageBundles = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityMid];
    });
    /// check Language
    NSString *finalLanguage = turing_supportLocaleForLocale(localeIdentifier);
    NSBundle *languageBundle = [languageBundles objectForKey:localeIdentifier ?: @""];
    if (languageBundle == nil) {
        languageBundle = [languageBundles objectForKey:finalLanguage];
    }
    if (languageBundle == nil) {
        NSString *languageBundleName = [NSString stringWithFormat:@"BDTuringLocalized-%@",finalLanguage];
        NSURL *URL = [[NSBundle mainBundle] URLForResource:languageBundleName withExtension:@"bundle"];
        /// like zh not exist
        if (URL == nil) {
            URL = [[NSBundle mainBundle] URLForResource:@"BDTuringLocalized-en" withExtension:@"bundle"];
        }
        languageBundle = [NSBundle bundleWithURL:URL];
        [languageBundles setValue:languageBundle forKey:finalLanguage];
        [languageBundles setValue:languageBundle forKey:localeIdentifier ?: @""];
    }
    
    return [languageBundle localizedStringForKey:key value:nil table:@"Localizable"];
}

NSString * turing_regionFromRegionType(BDTuringRegionType regionType) {
    switch (regionType) {
        case BDTuringRegionTypeCN:
            return kBDTuringRegionCN;
        case BDTuringRegionTypeSG:
            return kBDTuringRegionSG;
        case BDTuringRegionTypeVA:
            return kBDTuringRegionVA;
        case BDTuringRegionTypeIndia:
            return kBDTuringRegionIN;
    }

    return nil;
}


long long turing_duration_ms(long long start) {
    return CACurrentMediaTime() * 1000 - start;
}

BOOL BDTuring_isValidDictionary(NSDictionary *value) {
    if (value == nil) {
        return NO;
    }
    
    if (![value isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    return value.count > 0;
}

BOOL BDTuring_isValidArray(NSArray *value) {
    if (value == nil) {
        return NO;
    }
    
    if (![value isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    return value.count > 0;
}

BOOL BDTuring_isValidString(NSString *value) {
    if (value == nil) {
        return NO;
    }
    
    if (![value isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    return value.length > 0;
}

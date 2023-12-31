//
//  BDTuringUtility.h
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import "BDTuringDefine.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN long long turing_currentIntervalMS(void);
FOUNDATION_EXTERN NSString * turing_queryFromDictionary(NSDictionary *params);
FOUNDATION_EXTERN NSString * turing_requestURLWithQuery(NSString *requestURL, NSDictionary *query);
FOUNDATION_EXTERN NSString * turing_requestURLWithPath(NSString *requestURL, NSString *path);

FOUNDATION_EXTERN NSString * turing_sandBoxDocumentsPath(void);
FOUNDATION_EXTERN NSString * turing_sdkDocumentPath(void);
FOUNDATION_EXTERN NSString * turing_sdkDocumentPathForAppID(NSString *appID);
FOUNDATION_EXTERN NSString * turing_sdkDatabaseFile(void) ;
FOUNDATION_EXTERN NSBundle * turing_sdkBundle(void);
FOUNDATION_EXTERN NSString * _Nullable turing_LocalizedString(NSString *key, NSString *language);
FOUNDATION_EXTERN NSString * _Nullable turing_regionFromRegionType(BDTuringRegionType regionType);

FOUNDATION_EXTERN long long turing_duration_ms(long long start);

FOUNDATION_EXTERN BOOL BDTuring_isValidDictionary(NSDictionary *value);
FOUNDATION_EXTERN BOOL BDTuring_isValidArray(NSArray *value);
FOUNDATION_EXTERN BOOL BDTuring_isValidString(NSString *value);

NS_ASSUME_NONNULL_END

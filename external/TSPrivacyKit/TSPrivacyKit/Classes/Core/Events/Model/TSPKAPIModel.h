//
//  TSPKAPIModel.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import <Foundation/Foundation.h>



typedef NS_ENUM(NSUInteger, TSPKAPIUsageType) {
    TSPKAPIUsageTypeNotDefined,

    TSPKAPIUsageTypeStart,
    TSPKAPIUsageTypeStop,
    TSPKAPIUsageTypeDealloc,
    
    TSPKAPIUsageTypeInfo
};

typedef NS_ENUM(NSUInteger, TSPKAPIStoreType) {
    TSPKAPIStoreTypeNormal,
    TSPKAPIStoreTypeIgnoreStore,
    TSPKAPIStoreTypeOnlyStore
};

typedef NS_ENUM(NSUInteger, TSPKCheckResult) {
    TSPKCheckResultError,

    TSPKCheckResultRelease,
    TSPKCheckResultUnrelease,
};

typedef TSPKCheckResult (^TSPKReleaseCheckBlock)(NSObject *_Nullable obj);
typedef void (^TSPKDowngradeAction)(void);

@interface TSPKAPIModel : NSObject

@property (nonatomic, copy, nullable) NSString *pipelineType;
@property (nonatomic, copy, nullable) NSString *apiMethod;
@property (nonatomic, copy, nullable) NSString *apiClass;
@property (nonatomic, copy, nullable) NSString *dataType;
@property (nonatomic, copy, nullable) NSString *entryToken;
@property (nonatomic, assign) NSInteger apiId;
@property (nonatomic) TSPKAPIUsageType apiUsageType;
@property (nonatomic, weak, nullable) NSObject *instance;
@property (nonatomic, copy, nullable) NSString *hashTag;
@property (nonatomic, strong, nullable) NSNumber *errorCode;
@property (nonatomic) BOOL isDowngradeBehavior;
@property (nonatomic, copy, nullable) NSDictionary *params;
@property (nonatomic, assign) BOOL isNonsenstive;
@property (nonatomic, assign) BOOL isNonauth;
@property (nonatomic, assign) BOOL beforeOrAfterCall;
@property (nonatomic, assign) BOOL isCustomApi;

@property (nonatomic, copy, nullable) NSArray *backtraces;
@property (nonatomic, copy, nullable) NSString *bizLine; // used for biz api
@property (nonatomic, assign) TSPKAPIStoreType apiStoreType; // only used to store

@property (nonatomic, copy, nullable) TSPKReleaseCheckBlock customReleaseCheckBlock;
@property (nonatomic, copy, nullable) TSPKDowngradeAction downgradeAction;

@end



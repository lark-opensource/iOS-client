//Copyright © 2022 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, TSPKAspectMethodReturnType) {
    TSPKAspectMethodReturnNone,
    TSPKAspectMethodReturnNumeric,
    TSPKAspectMethodReturnObject,
    TSPKAspectMethodReturnStruct
};

typedef NS_ENUM(NSUInteger, TSPKAspectPosition) {
    TSPKAspectPositionPre,
    TSPKAspectPositionPost
};

typedef NS_ENUM(NSUInteger, TSPKAspectMethodType) {
    TSPKAspectMethodTypeUnknown,
    TSPKAspectMethodTypeInstance,
    TSPKAspectMethodTypeClass
};


@interface TSPKAspectModel : NSObject
@property(nonatomic, assign, readonly) TSPKAspectMethodReturnType returnTypeKind;
@property(nonatomic, assign, readonly) TSPKAspectPosition aspectPosition;//post or pre

@property(nonatomic, strong, nonnull) NSString *klassName;
@property(nonatomic, strong, nonnull) NSString *methodName;
@property(nonatomic, strong, nullable) NSString* returnType;
@property(nonatomic, strong, nullable) NSString* returnValue;
@property(nonatomic, strong, nullable) NSString* pipelineType;
@property(nonatomic, strong, nullable) NSString* dataType;
@property(nonatomic, strong, nullable) NSString* registerEntryType;
@property(nonatomic, assign) NSInteger apiId;
@property(nonatomic, assign) TSPKAspectMethodType methodType;
@property(nonatomic, assign) BOOL needLogCaller;
@property(nonatomic, assign) BOOL needFuse;
@property(nonatomic, assign) NSInteger storeType;
@property(nonatomic, assign) NSInteger apiUsageType;
@property(nonatomic, strong, nullable) NSString *detector;
@property(nonatomic, assign) BOOL enableDetector;
@property (nonatomic, copy, nullable) NSArray <NSString *> *actions;

@property(nonatomic, assign) BOOL aspectAllMethods;
@property(nonatomic, assign) BOOL ignoreInternalMethods;

- (instancetype _Nullable)initWithDictionary:(NSDictionary* _Nonnull)dict;

/// only fill it when pipelineType is nil && klassName and methodName exist
- (void)fillPipelineType;

@end

//
//  OPAppUniqueID.m
//  OPSDK
//
//  Created by yinyuan on 2020/12/16.
//

#import "OPAppUniqueID.h"
#import <objc/runtime.h>
#import "OPUtils.h"

static NSString * const kUniqueIDVersion = @"U1";

@interface OPAppUniqueID ()

@property (nonatomic, copy, readwrite) NSString *fullString;
@property (nonatomic, copy, readwrite) NSString *appID;
@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, assign, readwrite) OPAppVersionType versionType;
@property (nonatomic, assign, readwrite) OPAppType appType;

@end

@implementation OPAppUniqueID

#pragma mark - NSCopying Protocol

+(NSMutableDictionary<NSString *, OPAppUniqueID *> *)uniqueIDCache {
    /// 实现 uniqueID 的真唯一（包括内存地址的唯一）
    static NSMutableDictionary<NSString *, OPAppUniqueID *> *gUniqueIDMap;
    static dispatch_once_t onceTokenForUniqueIDMap;
    dispatch_once(&onceTokenForUniqueIDMap, ^{
        gUniqueIDMap = NSMutableDictionary.dictionary;
    });
    
    return gUniqueIDMap;
}

+(dispatch_semaphore_t)uniqueIDCacheLock {
    static dispatch_semaphore_t gUniqueIDMapLock;
    static dispatch_once_t onceTokenForUniqueIDMapLock;
    dispatch_once(&onceTokenForUniqueIDMapLock, ^{
        gUniqueIDMapLock = dispatch_semaphore_create(1);
    });
    
    return gUniqueIDMapLock;
}

/*-----------------------------------------------*/
//         NSCopying Protocol - Copy 协议
/*-----------------------------------------------*/
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark - Initialize
+ (instancetype _Nonnull)uniqueIDWithAppID:(NSString * _Nonnull)appID
                                identifier:(NSString * _Nullable)identifier
                               versionType:(OPAppVersionType)versionType
                                   appType:(OPAppType)appType
{
    return [self uniqueIDWithAppID:appID identifier:identifier versionType:versionType appType:appType instanceID:nil];
}

+ (instancetype _Nonnull)uniqueIDWithAppID:(NSString * _Nonnull)appID
                                identifier:(NSString * _Nullable)identifier
                               versionType:(OPAppVersionType)versionType
                                   appType:(OPAppType)appType
                                instanceID:(NSString * _Nullable)instanceID
{
    OPAppUniqueID *uniqueID = [[OPAppUniqueID alloc] initWithAppID:appID
                                                        identifier:identifier
                                                       versionType:versionType
                                                           appType:appType
                                                        instanceID:instanceID];
    // 尝试从缓存中读取已有的等价的 UniqueID
    NSString *fullString = uniqueID.fullString;
    dispatch_semaphore_wait(self.uniqueIDCacheLock, DISPATCH_TIME_FOREVER);
    OPAppUniqueID *tUniqueID = self.uniqueIDCache[fullString];
    if (tUniqueID) {
        uniqueID = tUniqueID;
    } else {
        self.uniqueIDCache[fullString] = uniqueID;
    }
    dispatch_semaphore_signal(self.uniqueIDCacheLock);
    
    return uniqueID;
}

+ (instancetype _Nonnull)uniqueIDWithFullString:(NSString * _Nonnull)fullString {
    
    if (fullString) {
        // 尝试从缓存中读取已有的等价的 UniqueID
        dispatch_semaphore_wait(self.uniqueIDCacheLock, DISPATCH_TIME_FOREVER);
        OPAppUniqueID *uniqueID = self.uniqueIDCache[fullString];
        dispatch_semaphore_signal(self.uniqueIDCacheLock);
        
        if (uniqueID) {
            return uniqueID;
        }
    }
    
    NSString *appID;
    NSString *identifier;
    OPAppVersionType versionType = OPAppVersionTypeCurrent;
    OPAppType appType = OPAppTypeUnknown;
    NSString *instanceID;
    
    NSArray<NSString *> *components = [fullString componentsSeparatedByString:@"-"];
    if (components.count >= 6) {
        if ([components[0] isEqualToString:kUniqueIDVersion]) {
            appID = components[1];
            identifier = components[2];
            versionType = OPAppVersionTypeFromString(components[3]);
            appType = OPAppTypeFromString(components[4]);
            instanceID = components[5];
        } else {
            NSAssert(!OPIsEmptyString(appID), @"BDPUniqueID.init: uniqueID version not match!");
        }
    } else {
        NSAssert(!OPIsEmptyString(appID), @"BDPUniqueID.init: fullString not match!");
    }
    
    return [self uniqueIDWithAppID:appID identifier:identifier versionType:versionType appType:appType instanceID:instanceID];
}
/*-----------------------------------------------*/
//             Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)init
{
    // 禁用默认的 init 函数
    NSAssert(NO, @"BDPUniqueID.init function is UNAVAILABLE!");
    return [self initWithAppID:@"" identifier:nil versionType:OPAppVersionTypeCurrent appType:OPAppTypeUnknown instanceID:nil];
}

- (instancetype _Nonnull)initWithAppID:(NSString * _Nonnull)appID
                            identifier:(NSString * _Nullable)identifier
                           versionType:(OPAppVersionType)versionType
                               appType:(OPAppType)appType
                            instanceID:(NSString * _Nullable)instanceID
{
    self = [super init];
    if (self) {
        if (appType != OPAppTypeWebApp) {
            // H5 一部分逻辑是没有 appID 的
            NSAssert(!OPIsEmptyString(appID), @"BDPUniqueID.init: appID should not be empty!");
        }
        _appID = OPIsEmptyString(appID) ? @"" : appID.copy;
        _versionType = versionType;
        _appType = appType;
        _identifier = OPIsEmptyString(identifier) ? _appID : identifier;
        _instanceID = OPIsEmptyString(instanceID) ? @"" : instanceID;
        _fullString = [OPAppUniqueID fullStringWithAppID:_appID
                                              identifier:_identifier
                                             versionType:_versionType
                                                 appType:_appType
                                              instanceID:_instanceID];
    }
    return self;
}

+ (NSString *)fullStringWithAppID:(NSString *)appID
                       identifier:(NSString * _Nonnull)identifier
                      versionType:(OPAppVersionType)versionType
                          appType:(OPAppType)appType
                       instanceID:(NSString * _Nonnull)instanceID {
    NSString *appTypeString = OPAppTypeToString(appType);
    NSString *versionTypeString = OPAppVersionTypeToString(versionType);
    return [NSString stringWithFormat:@"%@-%@-%@-%@-%@-%@", kUniqueIDVersion, appID, identifier, versionTypeString, appTypeString, instanceID];
}

- (BOOL)isEqualToUniqueID:(OPAppUniqueID *)uniqueID
{
    return [uniqueID isKindOfClass:[OPAppUniqueID class]] && [uniqueID.fullString isEqualToString:self.fullString];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else {
        return [self isEqualToUniqueID:other];
    }
}

- (NSUInteger)hash
{
    return self.fullString.hash;
}

- (NSString *)description
{
    return self.fullString;
}

- (BOOL)isValid {
    return !OPIsEmptyString(self.appID);
}

@end

@implementation OPAppUniqueID (OPDynamicComponentProperty)

static char kOPAppUniqueIDRequireVersionKey;
-(void)setRequireVersion:(NSString *)requireVersion
{
    if(self.appType == OPAppTypeDynamicComponent){
        objc_setAssociatedObject(self, &kOPAppUniqueIDRequireVersionKey, requireVersion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}
-(NSString *)requireVersion {
    if(self.appType == OPAppTypeDynamicComponent){
        return objc_getAssociatedObject(self, &kOPAppUniqueIDRequireVersionKey);
    }
    return @"";
}
@end

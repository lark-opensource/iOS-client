//
//  BDDYCModuleModel.m
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import "BDDYCModuleModel.h"
#import "BDDYCMacros.h"
#import "BDDYCSecurity.h"
#import "BDDYCModelKey.h"
#import "BDBDQuaterback+Internal.h"


/**
 加密私钥的Key
 */
static NSString *BDDYCGetPrivateKeyPrivateKey(NSString *randomString)
{
    return [NSString stringWithFormat:@"%@.com.bddQuaterback.Quaterback.key", randomString];
}

#pragma mark -

#if BDAweme
__attribute__((objc_runtime_name("AWECFWalrus")))
#elif BDNews
__attribute__((objc_runtime_name("TTDThistle")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDReindeer")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDRape")))
#endif
@interface BDDYCModuleModelDownloadingStatus : NSObject
@property (nonatomic,   copy) NSString *downloadingUrl;
// -1 is url, other is backupUrls 中信息
@property (nonatomic, assign) NSInteger nextUrlIdx;
@property (nonatomic, assign) NSInteger numberOfRetries;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableArray*> *urlToErrorMapper;
@end

@interface BDDYCModuleModel ()<BDQuaterbackConfigProtocol>
@property (nonatomic,   copy) NSString *uniqueKey;
@property (nonatomic, strong) BDDYCModuleModelDownloadingStatus *downloadingStatus;
@end

@implementation BDDYCModuleModel

@synthesize downloadingStatus = _downloadingStatus;

+ (instancetype)modelWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    if ((self = [self init])) {
        self.moduleId       = [NSString stringWithFormat:@"%@",dict[kBDDYCQuaterbackIDRespKey] ? : dict[kBDDYCModuleIDKey]];
        self.name           = dict[kBDDYCQuaterbackNameRespKey] ? : dict[kBDDYCNameRespKey];
        self.version        = dict[kBDDYCQuaterbackVersionRespKey];
        self.appVersion     = dict[kBDDYCAppVersionRespKey];
        self.appBuildVersion= dict[kBDDYCAppBuildVersionRespKey];
        self.url            = dict[kBDDYCQuaterbackUrlRespKey];
        
        NSArray *backupUrls = dict[kBDDYCQuaterbackBackupUrlsRespKey];
        self.backupUrls     = [backupUrls isKindOfClass:[NSArray class]] ? backupUrls : nil;
        self.md5            = dict[kBDDYCQuaterbackMD5RespKey];
        
        NSNumber *wifionlyN = dict[kBDDYCQuaterbackWifiOnlyRespKey];
        self.wifionly       = [wifionlyN respondsToSelector:@selector(boolValue)] ? [wifionlyN boolValue] : NO;

        NSNumber *asyncLoad = dict[kBDDYCQuaterbackAsyncLoad];
        self.async       = [asyncLoad respondsToSelector:@selector(boolValue)] ? [asyncLoad boolValue] : NO;

        NSArray *channelList = dict[kBDDYCQuaterbackChannel];
        self.channelList = [channelList isKindOfClass:[NSArray class]]?channelList:nil;

        NSArray *appVersionList = dict[kBDDYCQuaterbackAPPVersionList];
        self.appVersionList = [appVersionList isKindOfClass:[NSArray class]]?appVersionList:nil;

        NSDictionary *osRange = dict[kBDDYCQuaterbackOSVersionRange];
        self.osVersionRange = [osRange isKindOfClass:[NSDictionary class]]?osRange:nil;

        NSString *onOffN    = dict[kBDDYCQuaterbackOfflineRespKey];
        self.offline        = [onOffN respondsToSelector:@selector(integerValue)] ? [onOffN integerValue] : 0;

        NSString *opTypeStr = dict[kBDDYCQuaterbackOperationTypeRespKey];
        self.operationType  = [opTypeStr respondsToSelector:@selector(integerValue)] ? [opTypeStr integerValue] : 0;
        
        // encryption information
        NSNumber *isEncrypt = dict[kBDDYCEncryptStatusKey];
        self.encrypted      = [isEncrypt respondsToSelector:@selector(boolValue)] ? [isEncrypt boolValue] : NO;
        
        NSString *privateKey = dict[kBDDYCEncryptPrivateKeyKey];
        NSString *privateKeyKey = BDDYCGetPrivateKeyPrivateKey(self.name);
        if (privateKeyKey) {
            privateKey = [BDDYCSecurity AESDecryptString:privateKey
                                               keyString:privateKeyKey
                                                ivString:nil];
        }
        self.privateKey = privateKey;
    }
    return self;
}

- (NSDictionary *)toPropertyListDictionary
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.moduleId
                   forKey:kBDDYCQuaterbackIDRespKey];
    [mutableDict setValue:self.name
                   forKey:kBDDYCQuaterbackNameRespKey];
    [mutableDict setValue:self.version
                   forKey:kBDDYCQuaterbackVersionRespKey];
    [mutableDict setValue:self.appVersion
                   forKey:kBDDYCAppVersionRespKey];
    [mutableDict setValue:self.appBuildVersion
                   forKey:kBDDYCAppBuildVersionRespKey];
    [mutableDict setValue:self.url
                   forKey:kBDDYCQuaterbackUrlRespKey];
    [mutableDict setValue:self.backupUrls
                   forKey:kBDDYCQuaterbackBackupUrlsRespKey];
    [mutableDict setValue:self.md5
                   forKey:kBDDYCQuaterbackMD5RespKey];
    [mutableDict setValue:@(self.wifionly)
                   forKey:kBDDYCQuaterbackWifiOnlyRespKey];
    [mutableDict setValue:@(self.offline)
                   forKey:kBDDYCQuaterbackOfflineRespKey];
    [mutableDict setValue:@(self.isAsync)
                   forKey:kBDDYCQuaterbackAsyncLoad];

    [mutableDict setValue:self.channelList
                   forKey:kBDDYCQuaterbackChannel];
    [mutableDict setValue:self.appVersionList
                   forKey:kBDDYCQuaterbackAPPVersionList];
    [mutableDict setValue:self.osVersionRange
                   forKey:kBDDYCQuaterbackOSVersionRange];
    //
    [mutableDict setValue:@(self.operationType)
                   forKey:kBDDYCQuaterbackOperationTypeRespKey];
    [mutableDict setValue:@(self.encrypted)
                   forKey:kBDDYCEncryptStatusKey];
    NSString *privateKey = self.privateKey;
    NSString *privateKeyKey = BDDYCGetPrivateKeyPrivateKey(self.name);
    if (privateKeyKey) {
        privateKey = [BDDYCSecurity AESEncryptString:privateKey
                                           keyString:privateKeyKey
                                            ivString:nil];
    }
    [mutableDict setValue:privateKey
                   forKey:kBDDYCEncryptPrivateKeyKey];
    
    return [mutableDict copy];
}

- (NSDictionary *)toReportDicitonary
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:@([self.moduleId longLongValue])
                   forKey:kBDDYCQuaterbackIdReqKey];
    [mutableDict setValue:self.name
                   forKey:kBDDYCQuaterbackNameReqKey];
    [mutableDict setValue:self.version
                   forKey:kBDDYCQuaterbackVersionReqKey];
    return [mutableDict copy];
}

- (NSDictionary *)toLogDicitonary {
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.name
                   forKey:@"better_name"];
    [mutableDict setValue:self.version
                   forKey:@"version_code"];
    return [mutableDict copy];
}

- (instancetype)init
{
    if ((self = [super init])) {
        _uniqueKey = [[NSUUID UUID] UUIDString];
        _encrypted = NO;
        _offline   = NO;
    }
    return self;
}

- (BOOL)isHigherToObject:(BDDYCModuleModel *)otherModel
{
    if (!otherModel || !otherModel.version) return YES;
    if ([self.version floatValue] > [otherModel.version floatValue]) return YES;
    return NO;
}


- (BOOL)needsUpdateCompareToObject:(BDDYCModuleModel *)otherModel
{
    if (!otherModel) return YES;
    if ([self isHigherToObject:otherModel]) return YES;
    if (!self.md5 && !otherModel.md5) return NO;
    if (self.md5 && !otherModel.md5) return YES;
    if (![self.md5 isEqualToString:otherModel.md5]) return YES;
    return NO;
}

- (BDDYCModuleModelDownloadingStatus *)downloadingStatus
{
    if (!_downloadingStatus) {
        _downloadingStatus = [BDDYCModuleModelDownloadingStatus new];
    }
    return _downloadingStatus;
}

#pragma mark -

BDDYC_DEBUG_DESCRIPTION

#pragma mark - Getter/Setter

- (NSString *)uniquekey
{
    return _name ? : _uniqueKey;
}

@end



@implementation BDDYCModuleModel (ModelsCreation)

+ (NSArray *)modelsWithArray:(NSArray *)array
{
    if (!array || ![array isKindOfClass:[NSArray class]]) return nil;
    NSMutableArray *modelArray = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        BDDYCModuleModel *aModel = [BDDYCModuleModel modelWithDictionary:obj];
        if (aModel) [modelArray addObject:aModel];
    }];
    return modelArray;
}

+ (NSArray *)modelsWithDictionary:(NSDictionary *)dict
{
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    NSArray *moduleAlphas = dict[kBDDYCQuaterbackListRespKey];
    return [self modelsWithArray:moduleAlphas];
}

@end



@implementation BDDYCModuleModelDownloadingStatus

- (instancetype)init
{
    if ((self = [super init])) {
        _nextUrlIdx = -1;
        _numberOfRetries = 0;
    }
    return self;
}

- (void)retryWhenLargerThan:(NSInteger)limit
{
    if (_nextUrlIdx >= limit) {
        [self resetToRetry];
    }
}

- (void)resetToRetry
{
    if ([self retryEnabled]) {
        _numberOfRetries--;
        _nextUrlIdx = -1;
    }
}

- (BOOL)retryEnabled
{
    return _numberOfRetries > 0;
}

- (void)recordError:(NSError *)error forDownloadUrl:(NSString *)url
{
    if (!url || !error) return;
    if (!_urlToErrorMapper) _urlToErrorMapper = [NSMutableDictionary dictionary];
    if (!_urlToErrorMapper[url]) {
        _urlToErrorMapper[url] = [NSMutableArray array];
    }
    [(NSMutableArray *)_urlToErrorMapper[url] addObject:error];
}

- (NSError *)lastDownloadError
{
    if (_downloadingUrl) return [(NSMutableArray *)_urlToErrorMapper[_downloadingUrl] lastObject];
    for (NSArray *key in _urlToErrorMapper.allKeys) {
        NSMutableArray *errors = key ? _urlToErrorMapper[key] : nil;
        if ([errors lastObject]) return [errors lastObject];
    }
    return nil;
}

@end



@implementation BDDYCModuleModel (DownloadingStatus)

- (BOOL)containsAvailableUrl
{
    if (!_url && [_backupUrls count] == 0) return NO;
    if (!_downloadingStatus) return YES;
    if (![_downloadingStatus retryEnabled]) {
        if (_downloadingStatus.nextUrlIdx < 0) return YES;
        if (_downloadingStatus.nextUrlIdx >= _backupUrls.count) return NO;
    }
    return YES;
}

- (NSString *)nextDownloadUrl
{
    [_downloadingStatus retryWhenLargerThan:_backupUrls.count];
    
    NSInteger urlIdx = self.downloadingStatus.nextUrlIdx;
    NSString *urlString = nil;
    
    if (urlIdx == -1 && _url) urlString = _url;
    else if (urlIdx == -1) urlIdx = 0;
    if (!urlString && (urlIdx < (NSInteger)_backupUrls.count)) urlString = _backupUrls[urlIdx];
    if (urlString) self.downloadingStatus.nextUrlIdx = urlIdx + 1;
    
    return urlString;
}

- (void)startDownloadUrl:(NSString *)url
{
    self.downloadingStatus.downloadingUrl = url;
}

- (void)recordError:(NSError *)error forDownloadUrl:(NSString *)url
{
    [self.downloadingStatus recordError:error
                         forDownloadUrl:url];
}

- (NSError *)lastDownloadError
{
    return [_downloadingStatus lastDownloadError];
}

@end

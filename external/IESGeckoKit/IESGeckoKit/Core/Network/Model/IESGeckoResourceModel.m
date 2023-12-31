//
//  IESGurdResourceModel.m
//  IESGurdKit
//
//  Created by 01 on 17/6/30.
//

#import "IESGeckoResourceModel.h"

#import "IESGeckoDefines+Private.h"
#import "IESGurdUpdateStatisticModel.h"
#import "IESGurdPackagesExtraManager.h"

#define VALIDATE_DICTIONARY(__dictionary)       \
(__dictionary && [__dictionary isKindOfClass:[NSDictionary class]] && !IES_isEmptyDictionary(__dictionary))     \

@implementation IESGurdResourceStrategies

+ (instancetype)instanceWithDict:(NSDictionary *)dict
{
    IESGurdResourceStrategies *strategies = [IESGurdResourceStrategies new];
    if ([dict[@"del_if_download_failed"] isKindOfClass:[NSNumber class]]) {
        strategies.deleteIfDownloadFailed = [dict[@"del_if_download_failed"] boolValue];
    }
    
    if ([dict[@"del_old_pkg_before_download"] isKindOfClass:[NSNumber class]]) {
        strategies.deleteBeforeDownload = [dict[@"del_old_pkg_before_download"] boolValue];
    }
    
    return strategies;
}

@end

@implementation IESGurdResourceURLInfo

+ (IESGurdResourceURLInfo * _Nullable)instanceWithDict:(NSDictionary *)dict
{
    if (!VALIDATE_DICTIONARY(dict)) {
        return nil;
    }
    
    if (!dict[@"md5"] || ![dict[@"md5"] isKindOfClass:[NSString class]]) {
        return nil;
    }
    if (!dict[@"size"] || ![dict[@"size"] isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    if (!dict[@"domains"] || ![dict[@"domains"] isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    IESGurdResourceURLInfo *info = [IESGurdResourceURLInfo new];
    info.ID = [dict[@"id"] unsignedLongLongValue];
    info.md5 = dict[@"md5"];
    info.decompressMD5 = dict[@"decompress_md5"];
    info.packageSize = [dict[@"size"] unsignedLongLongValue];
    
    if(![info parseUrlList:dict]) {
        return nil;
    }
    
    return info;
}

- (BOOL)parseUrlList:(NSDictionary *)dict
{
    NSString *scheme = dict[@"schema"] ? : dict[@"scheme"];
    NSArray *domainsArray = dict[@"domains"];
    NSString *uri = dict[@"uri"];
    if (scheme.length == 0 || domainsArray.count == 0 || uri.length == 0) {
        return NO;
    }
    NSMutableArray *URLsArray = [NSMutableArray array];
    [domainsArray enumerateObjectsUsingBlock:^(NSString *domain, NSUInteger idx, BOOL *stop) {
        NSURLComponents *URLComponents = [[NSURLComponents alloc] init];
        URLComponents.scheme = scheme;
        URLComponents.host = domain;
        URLComponents.path = uri;
        NSString *URLString = URLComponents.URL.absoluteString;
        if (URLString.length > 0) {
            [URLsArray addObject:URLString];
        }
    }];
    if (URLsArray.count == 0) {
        return NO;
    }
    self.urlList = [URLsArray copy];
    return YES;
}

@end

@interface IESGurdResourceModel ()

@property (nonatomic, readwrite, copy) NSString *logId;

@end

@implementation IESGurdResourceModel

+ (instancetype _Nullable)instanceWithDict:(NSDictionary *)dict
                                     local:(NSDictionary *)local
                                     logId:(NSString *)logId
{
    if (!VALIDATE_DICTIONARY(dict)) {
        return nil;
    }
    
    if (!dict[@"package_version"] || ![dict[@"package_version"] isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    uint64_t version = [dict[@"package_version"] unsignedLongLongValue];
    
    if (!dict[@"channel"] || ![dict[@"channel"] isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *channel = dict[@"channel"];
    
    NSDictionary *contentDictionary = dict[@"content"];
    if (!VALIDATE_DICTIONARY(contentDictionary)) {
        return nil;
    }
    
    IESGurdResourceURLInfo *package = [IESGurdResourceURLInfo instanceWithDict:contentDictionary[@"package"]];
    if (!package) {
        return nil;
    }
    // v6里把package里面的id删了，为了防止代码改动过大，这个把version赋值给id
    package.ID = version;
    
    IESGurdResourceModel *resource = [IESGurdResourceModel new];
    resource.accessKey = dict[@"access_key"];
    resource.version = version;
    resource.channel = channel;
    resource.packageType = [dict[@"package_type"] integerValue];
    resource.package = package;
    resource.strategies = [IESGurdResourceStrategies instanceWithDict:contentDictionary[@"strategies"]];
    if (!resource.strategies.deleteBeforeDownload) {
        resource.patch = [IESGurdResourceURLInfo instanceWithDict:contentDictionary[@"patch"]];
    }
    if (dict[@"from"] && [dict[@"from"] isKindOfClass:[NSArray class]]) {
        resource.businessIdentifiers = dict[@"from"];
    }
    
    resource.retryDownload = YES;
    resource.updateStatisticModel = [[IESGurdUpdateStatisticModel alloc] init];
    resource.updateStatisticModel.createTime = [NSDate date];
    if (resource.patch) {
        resource.updateStatisticModel.patchID = resource.patch.ID;
    }
    
    int attrBit = [dict[@"attr_bit"] intValue];
    resource.isZstd = attrBit >> 0 & 1;
    resource.onDemand = attrBit >> 1 & 1;
    resource.alwaysOnDemand = attrBit >> 2 & 1;
    
    id localVersion = local[resource.accessKey][channel];
    if (localVersion != nil) {
        resource.localVersion = [localVersion unsignedLongLongValue];
    }
    resource.logId = logId;
    
    NSDictionary *extraDictionary = dict[@"biz_extra"];
    if (VALIDATE_DICTIONARY(extraDictionary) && extraDictionary.count > 0) {
        [[IESGurdPackagesExtraManager sharedManager] updateExtra:resource.accessKey
                                                         channel:channel
                                                            data:extraDictionary];
    } else {
        [[IESGurdPackagesExtraManager sharedManager] cleanExtraIfNeeded:resource.accessKey channel:channel];
    }
    
    resource.groupName = dict[@"group_name"];
    NSMutableArray *groups = [NSMutableArray array];
    [(NSArray *)dict[@"groups"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSString.class]) {
            [groups addObject:obj];
        }
    }];
    resource.groups = [groups copy];
    
    return resource;
}

- (IESGurdResourceModel *)fullPackageInstance
{
    IESGurdResourceModel *resource = [self commonPropertyInstance];
    resource.package = self.package;
    resource.isZstd = self.isZstd;
    resource.onDemand = self.onDemand;
    resource.alwaysOnDemand = self.alwaysOnDemand;
    resource.downloadPriority = IESGurdDownloadPriorityHigh;
    resource.updateStatisticModel = self.updateStatisticModel;
    // 不拷贝patch
    return resource;
}

- (IESGurdResourceModel *)commonPropertyInstance
{
    IESGurdResourceModel *resource = [IESGurdResourceModel new];
    resource.version = self.version;
    resource.accessKey = self.accessKey;
    resource.channel = self.channel;
    resource.packageType = self.packageType;
    resource.strategies = self.strategies;
    resource.groups = self.groups;
    resource.groupName = self.groupName;
    resource.businessIdentifiers = self.businessIdentifiers;
    resource.offlinePrefixURLsArray = self.offlinePrefixURLsArray;
    resource.retryDownload = self.retryDownload;
    resource.localVersion = self.localVersion;
    resource.logId = self.logId;
    return resource;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"ak:%@, channel:%@, version:%llu, packageType:%ld, isZstd:%d",
            self.accessKey, self.channel, self.version, self.packageType, self.isZstd];
}

- (void)putDataToDict:(NSMutableDictionary *)dict
{
    dict[@"access_key"] = self.accessKey;
    dict[@"id"] = @(self.package.ID);
    dict[@"is_zstd"] = self.isZstd ? @(1) : @(0);
    dict[@"channel"] = self.channel;
    
    if (self.localVersion > 0) dict[@"local_version"] = @(self.localVersion);
    if (self.logId.length > 0) dict[@"x_tt_logid"] = self.logId;
    if (self.packageType > 0) dict[@"package_type"] = @(self.packageType);
}

@end

#undef VALIDATE_DICTIONARY

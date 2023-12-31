//
//  IESEffectResourceResponseModel.m
//  Pods
//
//  Created by 赖霄冰 on 2019/8/8.
//

#import "IESEffectResourceResponseModel.h"
#import "NSArray+EffectPlatformUtils.h"

@implementation IESEffectResourceResponseModel
@synthesize iconURLs = _iconURLs;
@synthesize effectId = _effectId;

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"iconURI" : @"icon_uri",
             @"resourceList" : @"resource_list",
             @"urlPrefixes" : @"url_prefix",
             @"iconURLs" : @"iconURLs",
             @"idMap" : @"params",
             @"effectId" : @"effectId",
             @"needTriggerDownload" : @"needTriggerDownload",
             };
}

+ (NSValueTransformer *)resourceListJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectResourceModel class]];
}

- (void)generateAllURLs {
    [self iconURLs];
    [self.resourceList enumerateObjectsUsingBlock:^(IESEffectResourceModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj genFileDownloadURLsWithURLPrefixes:self.urlPrefixes];
    }];
}

- (NSArray<NSString *> *)iconURLs {
    if (!self.urlPrefixes.count || !self.iconURI.length) return nil;
    if (!_iconURLs) {
        NSMutableArray *iconURLs = [NSMutableArray arrayWithCapacity:self.urlPrefixes.count];
        for (NSString *urlPrefix in self.urlPrefixes) {
            [iconURLs addObject:[urlPrefix stringByAppendingString:self.iconURI]];
        }
        _iconURLs = iconURLs.copy;
    }
    return _iconURLs;
}

- (NSArray<NSString *> *)allResourcePaths {
    NSMutableArray *resourcePaths = [NSMutableArray arrayWithCapacity:self.resourceList.count];
    for (IESEffectResourceModel *resource in self.resourceList) {
        NSString *filePath = resource.filePath;
        if (filePath) {
            [resourcePaths addObject:filePath];
        }
    }
    return resourcePaths.copy;
}

- (BOOL)resourcesAllDownloaded {
    NSArray *resources = [self.resourceList ep_compact:^id _Nonnull(IESEffectResourceModel * _Nonnull obj) {
        return obj.resourceURI;
    }];
    return [self allResourcePaths].count == resources.count;
}

- (NSString *)effectId {
    if (!_effectId) {
        _effectId = [[NSUUID UUID] UUIDString];
    }
    return _effectId;
}

- (BOOL)isEqual:(IESEffectResourceResponseModel *)other
{
    if (other == self) {
        return YES;
    } else if (![other isMemberOfClass:self.class]) {
        return NO;
    } else {
        return [self.effectId isEqualToString:other.effectId];
    }
}

- (NSUInteger)hash
{
    return self.effectId.hash;
}

@end

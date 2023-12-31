//
//  IESGurdMultiAccessKeysRequest.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/11/10.
//

#import "IESGurdMultiAccessKeysRequest.h"

#import "IESGeckoDefines+Private.h"
#import "IESGeckoKit+Private.h"
#import "IESGurdResourceMetadataStorage.h"
#import "IESGurdRegisterManager.h"
#import "IESGurdKit+RequestBlocklist.h"
#import "IESGurdSettingsManager.h"
#import "IESGurdKit+Experiment.h"
#import "UIApplication+IESGurdKit.h"

@interface IESGurdMultiAccessKeysRequest ()

@property (nonatomic, strong) NSMutableArray<NSString *> *accessKeysArray;

// accessKey : @[ channel, ... ]
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *targetChannelsDictionary;
// accessKey : @[ groupName, ... ]
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *groupNamesDictionary;
// accessKey : @{ key : value }
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *customParamsDictionary;
// accessKey-channel : @[ @"identifier", ... ]
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *channelIdentifiersDictionary;
// accessKey-group : @"identifier"
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *groupIdentifiersDictionary;
// accesskey : @{ channel : version }
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *> *targetVersionsDictionary;
// identifier : completion
@property (nonatomic, strong) NSMutableDictionary<NSString *, IESGurdSyncStatusDictionaryBlock> *completionsDictionary;
// identifier : @(IESGurdDownloadPriority)
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *downloadPrioritiesDictionary;

@end

@implementation IESGurdMultiAccessKeysRequest

- (void)updateConfigWithParams:(IESGurdFetchResourcesParams *)params
{
    [self updateConfigWithParams:params completion:nil];
}

- (void)updateConfigWithParams:(IESGurdFetchResourcesParams *)params
                    completion:(IESGurdSyncStatusDictionaryBlock _Nullable)completion
{
    if (self.markIdentifier) {
        NSAssert(params.businessIdentifier.length > 0, @"BusinessIdentifier should not be nil");
    }
    @synchronized (self) {
        NSString *accessKey = params.accessKey;
        NSString *businessIdentifier = params.businessIdentifier;
        
        NSMutableArray *accessKeysArray = self.accessKeysArray;
        if (!accessKeysArray) {
            accessKeysArray = [NSMutableArray array];
            self.accessKeysArray = accessKeysArray;
        }
        if (![accessKeysArray containsObject:accessKey]) {
            [accessKeysArray addObject:accessKey];
        }
        
        // update params
        NSArray<NSString *> *channels = [params.channels iesgurdkit_filteredChannelsForAccessKey:accessKey];
        if (channels.count > 0) {
            [self addAccessKey:accessKey
                      channels:channels
            businessIdentifier:businessIdentifier];
        }
        NSString *groupName = params.groupName;
        if ([groupName iesgurdkit_shouldRequestGroupNameForForAccessKey:accessKey]) {
            [self addAccessKey:accessKey
                     groupName:groupName
            businessIdentifier:businessIdentifier];
        }
        
        if (params.targetVersionsDictionary.count > 0) {
            [self addAccessKey:accessKey targetVersions:params.targetVersionsDictionary];
        }
        
        NSMutableDictionary *customParams = [NSMutableDictionary dictionary];
        IESGurdRegisterModel *registerModel = [[IESGurdRegisterManager sharedManager] registerModelWithAccessKey:accessKey];
        if (registerModel.customParams) {
            [customParams addEntriesFromDictionary:registerModel.customParams];
        }
        [customParams addEntriesFromDictionary:params.customParams];
        NSString *businessVersion = params.SDKVersion;
        if (businessVersion.length == 0) {
            businessVersion = registerModel.version ? : IESGurdKitInstance.appVersion;
        }
        customParams[IESGurdCustomParamKeyBusinessVersion] = businessVersion;
        [self addAccessKey:accessKey customParams:[customParams copy]];
        
        // save completion
        if (completion) {
            [self addCompletion:completion businessIdentifier:businessIdentifier];
        }
        
        [self addDownloadPriority:params.downloadPriority businessIdentifier:businessIdentifier];
        self.retryDownload = params.retryDownload;
    }
}

- (NSDictionary *)paramsForRequest
{
    @synchronized (self) {
        NSMutableDictionary *deploymentsDictionary = [NSMutableDictionary dictionary];
        NSMutableDictionary *localDictionary = [NSMutableDictionary dictionary];
        
        [self.accessKeysArray enumerateObjectsUsingBlock:^(NSString *accessKey, NSUInteger idx, BOOL *stop) {
            NSArray *channels = [self targetChannelInfosArrayWithAccessKey:accessKey];
            NSArray *groups = [self groupNameInfosArrayWithAccessKey:accessKey];
            if (channels.count > 0 || groups.count > 0) {
                NSMutableDictionary *accessKeyParams = [NSMutableDictionary dictionary];
                accessKeyParams[@"target_channels"] = channels;
                accessKeyParams[@"group_name"] = groups;
                deploymentsDictionary[accessKey] = [accessKeyParams copy];
            }
        }];
        
        if (deploymentsDictionary.count == 0) {
            return nil;
        }
        
        IESGurdSettingsResponseExtra *extra = [IESGurdSettingsManager sharedInstance].extra;
        [[IESGurdResourceMetadataStorage copyActiveMetadataDictionary] enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary<NSString *,IESGurdActivePackageMeta *> *obj, BOOL *stop) {
            if ([extra.noLocalAk containsObject:accessKey]) {
                return;
            }
            
            NSMutableDictionary *localInfos = [NSMutableDictionary dictionary];
            [obj enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdActivePackageMeta *meta, BOOL *stop) {
                localInfos[channel] = @(meta.version);
            }];
            localDictionary[accessKey] = [localInfos copy];
        }];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[kIESGurdRequestConfigDeploymentsInfoKey] = [deploymentsDictionary copy];
        params[kIESGurdRequestConfigLocalInfoKey] = [localDictionary copy];
        params[kIESGurdRequestConfigRequestMetaKey] = [self requestMetaDictionary];
        
        NSMutableDictionary *customParams = [NSMutableDictionary dictionary];
        [self.customParamsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableDictionary<NSString *,NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
            customParams[key] = [obj copy];
        }];
        params[kIESGurdRequestConfigCustomInfoKey] = [customParams copy];
        
        return [params copy];
    }
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)targetChannelsMap
{
    @synchronized (self) {
        NSMutableDictionary *targetChannelsMap = [NSMutableDictionary dictionary];
        [self.targetChannelsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSMutableSet<NSString *> *channelsSet, BOOL *stop) {
            targetChannelsMap[accessKey] = channelsSet.allObjects;
        }];
        return [targetChannelsMap copy];
    }
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)targetGroupsMap
{
    @synchronized (self) {
        NSMutableDictionary *targetGroupsMap = [NSMutableDictionary dictionary];
        [self.groupNamesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSMutableArray<NSString *> *groups, BOOL *stop) {
            targetGroupsMap[accessKey] = [groups copy];
        }];
        return [targetGroupsMap copy];
    }
}

- (NSDictionary<NSString *, IESGurdSyncStatusDictionaryBlock> *)requestCompletions
{
    @synchronized (self) {
        return [self.completionsDictionary copy];
    }
}

- (NSDictionary<NSString *, NSNumber *> *)downloadPrioritiesMap
{
    @synchronized (self) {
        return [self.downloadPrioritiesDictionary copy];
    }
}

- (BOOL)isParamsValid
{
    @synchronized (self) {
        __block BOOL isParamsValid = NO;
        [self.accessKeysArray enumerateObjectsUsingBlock:^(NSString *accessKey, NSUInteger idx, BOOL *stop) {
            NSMutableSet *channels = self.targetChannelsDictionary[accessKey];
            if (channels.count > 0) {
                isParamsValid = YES;
                *stop = YES;
                return;
            }
            NSMutableArray<NSString *> *groupNames = self.groupNamesDictionary[accessKey];
            if (groupNames.count > 0) {
                isParamsValid = YES;
                *stop = YES;
            }
        }];
        return isParamsValid;
    }
}

#pragma mark - Private - UpdateParams

- (void)addAccessKey:(NSString *)accessKey channels:(NSArray<NSString *> *)channels businessIdentifier:(NSString *)businessIdentifier
{
    NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *targetChannelsDictionary = self.targetChannelsDictionary;
    if (!targetChannelsDictionary) {
        targetChannelsDictionary = [NSMutableDictionary dictionary];
        self.targetChannelsDictionary = targetChannelsDictionary;
    }
    
    NSMutableSet<NSString *> *targetChannels = targetChannelsDictionary[accessKey];
    if (!targetChannels) {
        targetChannels = [NSMutableSet set];
        targetChannelsDictionary[accessKey] = targetChannels;
    }
    
    [targetChannels addObjectsFromArray:channels];
    
    if (businessIdentifier.length == 0) {
        return;
    }
    
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *channelIdentifiersDictionary = self.channelIdentifiersDictionary;
    if (!self.channelIdentifiersDictionary) {
        channelIdentifiersDictionary = [NSMutableDictionary dictionary];
        self.channelIdentifiersDictionary = channelIdentifiersDictionary;
    }
    for (NSString *channel in channels) {
        NSString *identifierKey = [self identifierKeyWithAccessKey:accessKey channel:channel];
        NSMutableArray<NSString *> *channelIdentifiers = channelIdentifiersDictionary[identifierKey];
        if (!channelIdentifiers) {
            channelIdentifiers = [NSMutableArray array];
            channelIdentifiersDictionary[identifierKey] = channelIdentifiers;
        }
        if (![channelIdentifiers containsObject:businessIdentifier]) {
            [channelIdentifiers addObject:businessIdentifier];
        }
    }
}

- (void)addAccessKey:(NSString *)accessKey
      targetVersions:(NSDictionary<NSString *, NSNumber *> *)targetVersions
{
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *> *targetVersionsDictionary = self.targetVersionsDictionary;
    if (!targetVersionsDictionary) {
        targetVersionsDictionary = [NSMutableDictionary dictionary];
        self.targetVersionsDictionary = targetVersionsDictionary;
    }
    
    NSMutableDictionary<NSString *, NSNumber *> *channelVersionsMap = targetVersionsDictionary[accessKey];
    if (!channelVersionsMap) {
        channelVersionsMap = [NSMutableDictionary dictionary];
        targetVersionsDictionary[accessKey] = channelVersionsMap;
    }
    
    [channelVersionsMap addEntriesFromDictionary:targetVersions];
}

- (void)addAccessKey:(NSString *)accessKey groupName:(NSString *)groupName businessIdentifier:(NSString *)businessIdentifier
{
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *groupNamesDictionary = self.groupNamesDictionary;
    if (!groupNamesDictionary) {
        groupNamesDictionary = [NSMutableDictionary dictionary];
        self.groupNamesDictionary = groupNamesDictionary;
    }
    
    NSMutableArray<NSString *> *groupNames = groupNamesDictionary[accessKey];
    if (!groupNames) {
        groupNames = [NSMutableArray array];
        groupNamesDictionary[accessKey] = groupNames;
    }
    
    if (![groupNames containsObject:groupName]) {
        [groupNames addObject:groupName];
    }
    
    if (businessIdentifier.length == 0) {
        return;
    }
    
    NSMutableDictionary<NSString *, NSString *> *groupIdentifiersDictionary = self.groupIdentifiersDictionary;
    if (!groupIdentifiersDictionary) {
        groupIdentifiersDictionary = [NSMutableDictionary dictionary];
        self.groupIdentifiersDictionary = groupIdentifiersDictionary;
    }
    NSString *identifierKey = [self identifierKeyWithAccessKey:accessKey groupName:groupName];
    groupIdentifiersDictionary[identifierKey] = businessIdentifier;
}

- (void)addAccessKey:(NSString *)accessKey customParams:(NSDictionary<NSString *, NSString *> *)customParams
{
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *customParamsDictionary = self.customParamsDictionary;
    if (!customParamsDictionary) {
        customParamsDictionary = [NSMutableDictionary dictionary];
        self.customParamsDictionary = customParamsDictionary;
    }
    
    NSMutableDictionary<NSString *, NSString *> *params = customParamsDictionary[accessKey];
    if (!params) {
        params = [NSMutableDictionary dictionary];
        customParamsDictionary[accessKey] = params;
    }
    
    [params addEntriesFromDictionary:customParams];
}

- (void)addCompletion:(IESGurdSyncStatusDictionaryBlock)completion businessIdentifier:(NSString *)businessIdentifier
{
    if (businessIdentifier.length == 0 || !completion) {
        return;
    }
    NSMutableDictionary<NSString *, IESGurdSyncStatusDictionaryBlock> *completionsDictionary = self.completionsDictionary;
    if (!completionsDictionary) {
        completionsDictionary = [NSMutableDictionary dictionary];
        self.completionsDictionary = completionsDictionary;
    }
    completionsDictionary[businessIdentifier] = completion;
}

- (void)addDownloadPriority:(IESGurdDownloadPriority)downloadPriority businessIdentifier:(NSString *)businessIdentifier
{
    if (businessIdentifier.length == 0) {
        return;
    }
    NSMutableDictionary<NSString *, NSNumber *> *downloadPrioritiesDictionary = self.downloadPrioritiesDictionary;
    if (!downloadPrioritiesDictionary) {
        downloadPrioritiesDictionary = [NSMutableDictionary dictionary];
        self.downloadPrioritiesDictionary = downloadPrioritiesDictionary;
    }
    downloadPrioritiesDictionary[businessIdentifier] = @(downloadPriority);
}

#pragma mark - Private - RequestParams

- (NSArray<NSDictionary *> *)targetChannelInfosArrayWithAccessKey:(NSString *)accessKey
{
    int availableStorage = IESGurdKit.availableStoragePatch;
    BOOL isLowStorage = availableStorage > 0 && availableStorage > [UIApplication iesgurdkit_freeDiskSpace].doubleValue / 1024 / 1024;
    NSMutableArray *channelInfos = [NSMutableArray array];
    NSSet *channels = [self.targetChannelsDictionary[accessKey] copy];
    BOOL markIdentifier = self.markIdentifier;
    [channels enumerateObjectsUsingBlock:^(NSString *channel, BOOL *stop) {
        if (!isLowStorage || [IESGurdKit isInLowStorageWhiteList:accessKey channel:channel]) {
            NSMutableDictionary *channelInfo = [NSMutableDictionary dictionary];
            channelInfo[@"c"] = channel;
            if (markIdentifier) {
                NSString *identifierKey = [self identifierKeyWithAccessKey:accessKey channel:channel];
                NSArray<NSString *> *identifier = [self.channelIdentifiersDictionary[identifierKey] copy];
                channelInfo[@"from"] = identifier ? : @[];
            }
            uint64_t targetVersion = [self.targetVersionsDictionary[accessKey][channel] unsignedLongLongValue];
            if (targetVersion > 0) {
                channelInfo[@"t_v"] = @(targetVersion);
            }
            [channelInfos addObject:[channelInfo copy]];
        }
    }];
    return [channelInfos copy];
}

- (NSArray *)groupNameInfosArrayWithAccessKey:(NSString *)accessKey
{
    int availableStorage = IESGurdKit.availableStoragePatch;
    BOOL isLowStorage = availableStorage > 0 && availableStorage > [UIApplication iesgurdkit_freeDiskSpace].doubleValue / 1024 / 1024;
    NSArray<NSString *> *groupNames = [self.groupNamesDictionary[accessKey] copy] ? : @[];    
    NSMutableArray *groupNameInfos = [NSMutableArray array];
    for (NSString *groupName in groupNames) {
        if (!isLowStorage || [IESGurdKit isInLowStorageWhiteList:accessKey group:groupName]) {
            NSString *identifierKey = [self identifierKeyWithAccessKey:accessKey groupName:groupName];
            NSString *identifier = self.groupIdentifiersDictionary[identifierKey];
            [groupNameInfos addObject:@{ @"name" : groupName,
                                         @"from" : identifier ? : @"" }];
        }
    }
    return [groupNameInfos copy];
}

#pragma mark - Private - Keys

- (NSString *)identifierKeyWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [NSString stringWithFormat:@"%@-%@", accessKey, channel];
}

- (NSString *)identifierKeyWithAccessKey:(NSString *)accessKey groupName:(NSString *)groupName
{
    return [NSString stringWithFormat:@"%@-%@", accessKey, groupName];
}

#pragma mark - NSObject

- (NSString *)description
{
    @synchronized (self) {
        NSString *channelsString = @"";
        if (self.targetChannelsDictionary.count > 0) {
            channelsString = [NSString stringWithFormat:@"channels : %@ ", [self.targetChannelsDictionary description]];
        }
        NSString *groupsString = @"";
        if (self.groupNamesDictionary.count > 0) {
            groupsString = [NSString stringWithFormat:@"groups : %@ ", [self.groupNamesDictionary description]];
        }
        NSString *customParamsString = @"";
        if (self.customParamsDictionary.count > 0) {
            customParamsString = [NSString stringWithFormat:@"params : %@ ", [self.customParamsDictionary description]];
        }
        
        return [NSString stringWithFormat:@"%@%@%@",
                channelsString, groupsString, customParamsString];
    }
}

@end

@implementation IESGurdMultiAccessKeysRequest (DebugInfo)

- (NSString *)paramsString
{
    @synchronized (self) {
        NSMutableArray *paramsStringArray = [NSMutableArray array];
        if (self.targetChannelsDictionary.count > 0) {
            [paramsStringArray addObject:@"Channels :"];
            [paramsStringArray addObject:[self readableStringWithDictionary:self.targetChannelsDictionary]];
        }
        if (self.groupNamesDictionary.count > 0) {
            [paramsStringArray addObject:@"Groups :"];
            [paramsStringArray addObject:[self readableStringWithDictionary:self.groupNamesDictionary]];
        }
        if (self.customParamsDictionary.count > 0) {
            [paramsStringArray addObject:@"CustomParams :"];
            [paramsStringArray addObject:[self readableStringWithDictionary:self.customParamsDictionary]];
        }
        return [paramsStringArray componentsJoinedByString:@"\n"];
    }
}

- (NSString *)readableStringWithDictionary:(NSDictionary *)dictionary
{
    NSMutableString *readableString = [NSMutableString string];
    NSInteger count = dictionary.count;
    __block NSInteger index = 1;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [readableString appendString:[NSString stringWithFormat:@"%@ : %@", key, obj]];
        if (index != count) {
            [readableString appendString:@"\n"];
            index++;
        }
    }];
    return [readableString copy];
}

@end

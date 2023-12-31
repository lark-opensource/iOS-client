//
//  BDPSchema.m
//  Timor
//
//  Created by liubo on 2019/3/11.
//

#import "BDPSchema.h"
#import "BDPUtils.h"
#import "BDPSchemaCodec.h"

#import "BDPSchema+Private.h"
#import "BDPSchemaCodec+Private.h"
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

#pragma mark - BDPSchemaVersion

NSString * const BDPSchemaVersionV00 = @"v0";
NSString * const BDPSchemaVersionV01 = @"v1";
NSString * const BDPSchemaVersionV02 = @"v2";

#pragma mark - BDPSchema

@implementation BDPSchema

#pragma mark - Life Cycle

- (instancetype)init NS_UNAVAILABLE {
    return nil;
}

- (instancetype)initWithURL:(NSURL *)url appType:(OPAppType)appType {
    if (self = [super init]) {
        self.originURL = url;
        self.schemaVersion = BDPSchemaVersionV00;
        _appType = appType;
    }
    return self;
}

#pragma mark - Interface: Update

- (void)updateStartPage:(NSString *)startPage {
    [self setStartPage:startPage];
    //拆分start_page
    [BDPSchemaCodec constructStartPageForSchema:self];
}

- (void)updateScene:(NSString *)scene {
    [self setScene:scene];
}

- (void)updateLaunchFrom:(NSString *)launchFrom {
    self.launchFrom = launchFrom;
    if (!BDPIsEmptyDictionary(self.bdpLogDictionary)) {
        if ([self.bdpLogDictionary objectForKey:BDPSchemaBDPLogKeyLaunchFrom]) {
            NSMutableDictionary *bdplog = [self.bdpLogDictionary mutableCopy];
            [bdplog setValue:launchFrom forKey:BDPSchemaBDPLogKeyLaunchFrom];

            self.bdpLogDictionary = [bdplog copy];
            self.bdpLog = [[BDPSchemaCodec urlEncodeJSONRepresentationForObj:self.bdpLogDictionary] URLDecodedString];
        }
    }
}

- (void)updateRefererInfoDictionary:(NSDictionary *)refererInfoDictionary {
    [self setRefererInfoDictionary:refererInfoDictionary];
}

#pragma mark - Interface: App

#pragma mark - Interface: uniqueID
- (OPAppUniqueID * _Nonnull)uniqueID {
    return [OPAppUniqueID uniqueIDWithAppID:self.appID identifier:self.identifier versionType:self.versionType appType:self.appType instanceID:self.instanceID];
}

#pragma mark - Interface: Meta

- (NSString *)name {
    if (BDPIsEmptyDictionary(self.meta)) {
        return nil;
    }
    return [self.meta bdp_stringValueForKey:@"name"];
}

- (NSString *)iconURL {
    if (BDPIsEmptyDictionary(self.meta)) {
        return nil;
    }
    return [self.meta bdp_stringValueForKey:@"icon"];
}

#pragma mark - Interface: Common Params For Event Track

- (NSString *)location {
    if (!BDPIsEmptyDictionary(self.bdpLogDictionary)) {
        NSString *result = [self.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyLocation];
        if (!BDPIsEmptyString(result)) return result;
    }
    return nil;
}

- (NSString *)bizLocation {
    if (!BDPIsEmptyDictionary(self.bdpLogDictionary)) {
        NSString *result = [self.bdpLogDictionary bdp_stringValueForKey:BDPSchemaBDPLogKeyBizLocation];
        if (!BDPIsEmptyString(result)) return result;
    }
    return nil;
}

#pragma mark - Extra

- (NSString *)stringValueFromExtraForKey:(NSString *)key {
    if (BDPIsEmptyString(key)) return nil;
    
    if (!BDPIsEmptyDictionary(self.extraDictionary)) {
        NSString *result = [self.extraDictionary bdp_stringValueForKey:key];
        if (result != nil) return [result copy];
    }
    
    return nil;
}

- (NSArray *)arrayValueFromExtraForKey:(NSString *)key {
    if (BDPIsEmptyString(key)) return nil;
    
    if (!BDPIsEmptyDictionary(self.extraDictionary)) {
        NSArray *result = [self.extraDictionary bdp_arrayValueForKey:key];
        if (result != nil) return [result copy];
    }
    
    return nil;
}

- (NSDictionary *)dictionaryValueFromExtraForKey:(NSString *)key {
    if (BDPIsEmptyString(key)) return nil;
    
    if (!BDPIsEmptyDictionary(self.extraDictionary)) {
        NSDictionary *result = [self.extraDictionary bdp_dictionaryValueForKey:key];
        if (result != nil) return [result copy];
    }
    
    return nil;
}

#pragma mark - Protocol

- (id)copyWithZone:(NSZone *)zone {
    BDPSchema *schema = [[BDPSchema allocWithZone:zone] initWithURL:[self originURL] appType:self.appType];
    
    [schema setError:self.error];
    
    [schema setSchemaVersion:self.schemaVersion];
    [schema setOriginQueryParams:self.originQueryParams];
    
    [schema setProtocol:self.protocol];
    [schema setHost:self.host];
    [schema setFullHost:self.fullHost];
    
    [schema setAppID:self.appID];
    [schema setIdentifier:self.identifier];
    [schema setInstanceID:self.instanceID];
    
    [schema setVersionType:self.versionType];
    [schema setToken:self.token];
    
    [schema setMeta:self.meta];
    
    [schema setUrl:self.url];
    [schema setUrlDictionary:self.urlDictionary];
    
    [schema setTtid:self.ttid];
    [schema setLaunchFrom:self.launchFrom];
    
    [schema setScene:self.scene];
    [schema setSubScene:self.subScene];
    
    [schema setStartPage:self.startPage];
    [schema setStartPagePath:self.startPagePath];
    [schema setStartPageQuery:self.startPageQuery];
    [schema setStartPageQueryDictionary:self.startPageQueryDictionary];
    
    [schema setQuery:self.query];
    [schema setQueryDictionary:self.queryDictionary];
    
    [schema setExtra:self.extra];
    [schema setExtraDictionary:self.extraDictionary];
    
    [schema setBdpLog:self.bdpLog];
    [schema setBdpLogDictionary:self.bdpLogDictionary];
    
    [schema setRefererInfoDictionary:self.refererInfoDictionary];
    
    [schema setShareTicket:self.shareTicket];
    
    [schema setOriginEntrance:self.originEntrance];
    
    [schema setSnapshotUrl:self.snapshotUrl];
    
    [schema setWsForDebug:self.wsForDebug];
    [schema setIdeDisableDomainCheck:self.ideDisableDomainCheck];
    
    [schema setMode:self.mode];
    [schema setXScreenPresentationStyle:self.XScreenPresentationStyle];
    [schema setChatID:self.chatID];
    
    return schema;
}

///该方法仅用于description输出
- (NSDictionary *)toDictionary {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setValue:self.error forKey:@"error"];
    
    [dictionary setValue:self.schemaVersion forKey:@"schemaVersion"];
    
    [dictionary setValue:self.protocol forKey:@"protocol"];
    [dictionary setValue:self.host forKey:@"host"];
    [dictionary setValue:self.fullHost forKey:@"fullHost"];
    
    [dictionary setValue:self.appID forKey:@"appID"];
    [dictionary setValue:self.identifier forKey:@"identifier"];
    [dictionary setValue:self.instanceID forKey:@"instanceID"];
    
    [dictionary setValue:OPAppVersionTypeToString(self.versionType) forKey:@"versionType"];
    [dictionary setValue:self.token forKey:@"token"];
    
    [dictionary setValue:self.meta forKey:@"meta"];
    
    [dictionary setValue:self.urlDictionary forKey:@"urlDictionary"];
    
    [dictionary setValue:self.ttid forKey:@"ttid"];
    [dictionary setValue:self.launchFrom forKey:@"launchFrom"];
    
    [dictionary setValue:self.scene forKey:@"scene"];
    [dictionary setValue:self.subScene forKey:@"subscene"];
    
    [dictionary setValue:self.startPagePath forKey:@"startPagePath"];
    [dictionary setValue:self.startPageQuery forKey:@"startPageQuery"];
    [dictionary setValue:self.startPageQueryDictionary forKey:@"startPageQueryDictionary"];
    
    [dictionary setValue:self.query forKey:@"query"];
    [dictionary setValue:self.queryDictionary forKey:@"queryDictionary"];
    
    [dictionary setValue:self.extraDictionary forKey:@"extraDictionary"];
    
    [dictionary setValue:self.bdpLogDictionary forKey:@"bdpLogDictionary"];
    
    [dictionary setValue:self.refererInfoDictionary forKey:@"referInfoDictionary"];
    
    [dictionary setValue:self.shareTicket forKey:@"shareTicket"];
    
    [dictionary setValue:self.snapshotUrl forKey:@"snapshotUrl"];
    
    [dictionary setValue:self.wsForDebug forKey:@"ws_for_debug"];
    
    [dictionary setValue:self.ideDisableDomainCheck forKey:@"ide_disable_domain_check"];
    
    return [dictionary copy];
}

- (NSString *)description {
    return [[[self toDictionary] JSONRepresentation] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
}

- (NSString *)groupId {
    NSDictionary *eventExtra = [self dictionaryValueFromExtraForKey:@"event_extra"];
    NSString *groupId = [eventExtra bdp_stringValueForKey:@"group_id"];
    if (BDPIsEmptyString(groupId)) {
        groupId = [[self bdpLogDictionary] bdp_stringValueForKey:@"group_id"];
    }
    
    return groupId;
}

- (NSString *)launchType
{
    NSString *type = self.originQueryParams[BDPLaunchTypeKey];
    if (type) {
        return type;
    }else
    {
        return BDPLaunchTypeNormal;
    }
}
@end

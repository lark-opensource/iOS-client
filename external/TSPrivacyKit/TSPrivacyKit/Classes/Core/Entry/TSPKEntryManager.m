//
//  TSPKEntryManager.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/22.
//

#import "TSPKEntryManager.h"
#import "TSPKEntryUnit.h"
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKConfigs.h"
#import "TSPKUtils.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface TSPKEntryManager ()

@property (nonatomic) TSPKCustomCanHandleBuilder customCanHandleBuilder;
@property (nonatomic, strong) NSMutableDictionary *entries;
@property (nonatomic, strong) NSMutableDictionary *entryEnableDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, TSPKAPIModel *> *apiModelDict;

@end

@implementation TSPKEntryManager

+ (instancetype)sharedManager
{
    static TSPKEntryManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TSPKEntryManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _entries = [NSMutableDictionary dictionary];
        _entryEnableDict = [NSMutableDictionary dictionary];
        _apiModelDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerCustomCanHandleBuilder:(TSPKCustomCanHandleBuilder)builder {
    self.customCanHandleBuilder = builder;
}

- (void)registerEntryType:(NSString *)entryType entryModel:(TSPKEntryUnitModel *)entryModel
{
    if (entryType.length == 0) {
        return;
    }
    
    // has been registered
    if (_entries[entryType] != nil) {
        return;
    }
    
    TSPKEntryUnit *unit = [[TSPKEntryUnit alloc] initWithModel:entryModel];
    unit.entryType = entryType;
    _entries[entryType] = unit;
    
    [self buildEntryModelToDict:entryModel];
    
    BOOL enable = [_entryEnableDict[entryType] boolValue];
    if (enable) {
        [unit setEnable:YES];
    }
}

- (void)setEntryType:(NSString *)entryType enable:(BOOL)enable
{
    _entryEnableDict[entryType] = @(enable);
    
    if (_entries[entryType] == nil) {
        return;
    }
    
    TSPKEntryUnit *unit = (TSPKEntryUnit *)_entries[entryType];
    [unit setEnable:enable];
}

- (TSPKHandleResult *)didEnterEntry:(NSString *)entryType withModel:(TSPKAPIModel *)model
{
    if ([self canHandleEntry:entryType withModel:model]) {
        return [self handleEnterEntry:entryType withModel:model];
    }
    
    return nil;
}

/// priority: api > pipeline type > data type
/// etc...
/// for example, if pipeline enable, but api disable, sdk will do nothing.
- (BOOL)canHandleEntry:(NSString *)entryType withModel:(TSPKAPIModel *)model {
    if (_entries[entryType] == nil) {
        return NO;
    }
    
    if (self.customCanHandleBuilder && !self.customCanHandleBuilder(model)) {
        return NO;
    }
    
    NSNumber *isApiEnable = [[TSPKConfigs sharedConfig] isApiEnable:[TSPKUtils concateClassName:model.apiClass method:model.apiMethod]];
    if (isApiEnable != nil) {
        return [isApiEnable boolValue];
    }
    
    NSNumber *isPipelineEnable = [[TSPKConfigs sharedConfig] isPipelineEnable:model.pipelineType];
    if (isPipelineEnable != nil) {
        return [isPipelineEnable boolValue];
    }
    
    NSNumber *isDataTypeEnable = [[TSPKConfigs sharedConfig] isDataTypeEnable:model.dataType];
    if (isDataTypeEnable != nil) {
        return [isDataTypeEnable boolValue];
    }
    
    return YES;
}

- (TSPKHandleResult *)handleEnterEntry:(NSString *)entryType withModel:(TSPKAPIModel *)model {
    // ALog info
    NSString *message = [NSString stringWithFormat:@"didEnterEntry: id=%zd, class=%@, method=%@, type=%@", model.apiId, model.apiClass, model.apiMethod, model.pipelineType];
    [TSPKLogger logWithTag:TSPKLogCommonTag message:message];
    TSPKEntryUnit *unit = (TSPKEntryUnit *)_entries[entryType];
    return [unit handleAccessEntry:model];
}

- (BOOL)respondToEntryToken:(NSString *_Nullable)entryToken context:(NSDictionary *_Nullable)context
{
    if (entryToken.length == 0 || !context) {
        return NO;
    }
    
    NSArray *dataTypes = [context btd_arrayValueForKey:@"data_types" default:nil];
    if (!dataTypes) {
        return NO;
    }
    NSString *dataType = dataTypes.firstObject;
    if (!dataType) {
        return NO;
    }
    NSString *key = [NSString stringWithFormat:@"%@_%@", dataType, entryToken];
    TSPKAPIModel *apiModel = self.apiModelDict[key];
    if (apiModel == nil) {
        return NO;
    }
    BOOL canHandleEntry = [self canHandleEntry:apiModel.pipelineType withModel:apiModel];
    BOOL canHandleEventModel = [self canHandleEventModel:apiModel];
    
    return canHandleEntry && canHandleEventModel;
}

- (BOOL)canHandleEventModel:(TSPKAPIModel *)model {
    NSNumber *isRuleEngineApiEnable = [[TSPKConfigs sharedConfig] isRuleEngineApiEnable:[TSPKUtils concateClassName:model.apiClass method:model.apiMethod]];
    if (isRuleEngineApiEnable != nil) {
        return [isRuleEngineApiEnable boolValue];
    }
    
    NSNumber *isRuleEnginePipelineEnable = [[TSPKConfigs sharedConfig] isRuleEnginePipelineEnable:model.pipelineType];
    if (isRuleEnginePipelineEnable != nil) {
        return [isRuleEnginePipelineEnable boolValue];
    }
    
    NSNumber *isRuleEngineDataTypeEnable = [[TSPKConfigs sharedConfig] isRuleEngineDataTypeEnable:model.dataType];
    if (isRuleEngineDataTypeEnable != nil) {
        return [isRuleEngineDataTypeEnable boolValue];
    }
    
    return YES;
}

#pragma mark - Private

- (void)buildEntryModelToDict:(TSPKEntryUnitModel *)entryModel
{
    NSArray<NSString *> *apis = entryModel.apis;
    for (NSString *api in apis) {
        [self buildAPI:api ofEntryModel:entryModel apiClass:entryModel.clazzName];
    }
    NSArray<NSString *> *cApis = entryModel.cApis;
    for (NSString *api in cApis) {
        [self buildAPI:api ofEntryModel:entryModel apiClass:nil];
    }
}

- (void)buildAPI:(NSString *)api ofEntryModel:(TSPKEntryUnitModel *)entryModel apiClass:(NSString *)clazzName
{
    TSPKAPIModel *apiModel = [TSPKAPIModel new];
    apiModel.pipelineType = entryModel.pipelineType;
    apiModel.apiMethod = api;
    apiModel.apiClass = clazzName;
    apiModel.dataType = entryModel.dataType;
    apiModel.entryToken = clazzName ? [NSString stringWithFormat:@"%@_%@", clazzName, api] : api;
    NSString *key = [NSString stringWithFormat:@"%@_%@", entryModel.dataType, apiModel.entryToken];
    self.apiModelDict[key] = apiModel;
}

@end

//
//  CJPayFeatureCollectorManager.m
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/5/20.
//

#import "CJPayFeatureCollectorManager.h"
#import "CJPaySDKMacro.h"
#import "CJPayLocalCacheManager.h"
#import "CJPayAIEnginePlugin.h"

@implementation CJPayFeatureCollectContext

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:self.class]) {
        NSString *objName = ((CJPayFeatureCollectContext *)object).page;
        return [objName isEqualToString:self.page];
    }
    return NO;
}

- (NSUInteger)hash {
    return [self.page hash];
}

@end

@interface CJPayFeatureCollectorManager()<CJPayFeatureRecord>

@property (nonatomic, strong) NSMutableArray<id<CJPayFeatureCollector>> *collectors;
@property (nonatomic, strong) CJPayLocalCacheManager *manager;
@property (nonatomic, strong) NSMutableArray<CJPayFeatureCollectContext *> *contextStack;

@end

@implementation CJPayFeatureCollectorManager

- (void)registerCollector:(id<CJPayFeatureCollector>)collector {
    [self.collectors btd_addObject:collector];
    collector.recordManager = self;
}

- (instancetype)init {
    self = [super init];
    [self.manager loadCache];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)enterScene:(NSString *)sceneName {
    CJPayFeatureCollectContext *context = [CJPayFeatureCollectContext new];
    context.page = sceneName;
    if ([self.contextStack containsObject:context]) {
        [self.contextStack removeObject:context];
    }
    [self.contextStack addObject:context];
    [self startFeaturesCollect];
}

- (void)leaveScene:(NSString *)sceneName {
    CJPayFeatureCollectContext *context = [CJPayFeatureCollectContext new];
    context.page = sceneName;
    if ([self.contextStack containsObject:context]) {
        [self.contextStack removeObject:context];
    }
    if (self.contextStack.count <= 0) {
        [self stopFeaturesCollect];
    }
}

- (void)startFeaturesCollect {
    NSArray *cs = [self.collectors copy];
    [cs enumerateObjectsUsingBlock:^(id<CJPayFeatureCollector>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(beginCollect)]) {
            [obj beginCollect];
        }
    }];
}

- (void)stopFeaturesCollect {
    NSArray *cs = [self.collectors copy];
    [cs enumerateObjectsUsingBlock:^(id<CJPayFeatureCollector>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(endCollect)]) {
            [obj endCollect];
        }
    }];
}

- (NSArray<CJPayBaseSafeFeature *> *)allFeaturesFor:(NSString *)name conditionBlock:(nonnull BOOL (^)(CJPayBaseSafeFeature * _Nonnull))conditionBlock{
    return [self.manager allFeaturesFor:name conditionBlock:conditionBlock];
}

- (void)recordFeature:(CJPayBaseSafeFeature *)feature {
    [self.manager appendFeature:feature];
}

- (CJPayFeatureCollectContext *)getContext {
    return [self.contextStack lastObject];
}

- (NSDictionary *)buildFeaturesParams {
    NSMutableDictionary *deviceDict = [NSMutableDictionary new];
    NSMutableDictionary *intentionDict = [NSMutableDictionary new];
    NSArray *cs = [self.collectors copy];
    [cs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(buildDeviceParams)]) {
            [deviceDict addEntriesFromDictionary:[obj buildDeviceParams]];
        }
        if ([obj respondsToSelector:@selector(buildIntentionParams)]) {
            [intentionDict addEntriesFromDictionary:[obj buildIntentionParams]];
        }
    }];
    NSMutableDictionary *wholeDict = [NSMutableDictionary new];
    [wholeDict cj_setObject:deviceDict forKey:@"device_feat"];
    [wholeDict cj_setObject:intentionDict forKey:@"intention_feat"];
    id<CJPayAIEnginePlugin> aiEngine = CJ_OBJECT_WITH_PROTOCOL(CJPayAIEnginePlugin);
    if (aiEngine) {
        NSDictionary *pitayaDict = [aiEngine getOutputForBusiness:CAIJING_RISK_SDK_FEATURE];
        [wholeDict cj_setObject:pitayaDict forKey:CAIJING_RISK_SDK_FEATURE];
    }
    return [wholeDict copy];
}

- (NSMutableArray<CJPayFeatureCollectContext *> *)contextStack {
    if (!_contextStack) {
        _contextStack = [NSMutableArray new];
    }
    return _contextStack;
}

- (NSMutableArray<id<CJPayFeatureCollector>> *)collectors {
    if (!_collectors) {
        _collectors = [NSMutableArray new];
    }
    return _collectors;
}

- (CJPayLocalCacheManager *)manager {
    if (!_manager) {
        _manager = [CJPayLocalCacheManager new];
    }
    return _manager;
}

@end

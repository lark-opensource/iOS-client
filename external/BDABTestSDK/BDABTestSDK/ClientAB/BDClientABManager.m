//
//  BDClientABManager.m
//  ABTest
//
//  Created by ZhangLeonardo on 16/1/19.
//  Copyright © 2016年 ZhangLeonardo. All rights reserved.
//

#import "BDClientABManager.h"
#import "BDClientABStorageManager.h"
#import "BDClientABManagerUtil.h"
#import "BDABTestManager+Private.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>

#define kBDClientABGroupSeparator @","
#define kBDClientABFeatureSeparator @","

#define kFilterKeysDefaultKey @"__default_key"
#define kExplermentDefaultGroupNameKey @"__default_key"


@interface BDClientABManager()

//与app版本相同，同一version无须重复计算实验命中情况
@property (atomic, copy) NSString *appVersionStr;
@property (nonatomic, strong) BDClientABStorageManager *localStorageManager;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDClientABTestLayer *> *clientLayers;

@end

@implementation BDClientABManager

+ (instancetype)sharedManager
{
    static BDClientABManager *sharedInst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [self new];
        sharedInst.localStorageManager = [[BDClientABStorageManager alloc] init];
        sharedInst.clientLayers = [NSMutableDictionary dictionary];
    });
    return sharedInst;
}

- (BOOL)registerClientLayer:(BDClientABTestLayer *)clientLayer
{
    @synchronized (self.clientLayers) {
        if ([self.clientLayers objectForKey:clientLayer.name]) {
            [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"layer named %@ already exists.",clientLayer.name]];
            return NO;
        }
        if (![clientLayer isLegal]) {
            return NO;
        }
        [self.clientLayers setObject:clientLayer forKey:clientLayer.name];
        return YES;
    }
}

- (BDClientABTestLayer *)clientLayerByName:(NSString *)name
{
    @synchronized (self.clientLayers) {
        return [self.clientLayers objectForKey:name];
    }
}

//确保本地分流实验都注册后，才能调用此方法
- (void)launchClientExperimentManager
{
    self.appVersionStr = [self.localStorageManager AppVersion];
    if ([self.appVersionStr isEqualToString:[BDClientABManagerUtil appVersion]]) {
        //当前版本命中情况已经计算过
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB version %@ has been caculated, using cache.",self.appVersionStr]];
        [self sendABClientLayer];
        return;
    }
    [[BDABTestManager sharedManager] doLog:@"ClientAB begin caculating."];
    NSMutableDictionary *newRandomDic = [NSMutableDictionary dictionaryWithCapacity:[self.clientLayers count]];
    NSMutableDictionary *newLayer2GroupMap = [NSMutableDictionary dictionaryWithCapacity:[self.clientLayers count]];
    NSMutableDictionary *newFeatureDic = [NSMutableDictionary dictionaryWithCapacity:[self.clientLayers count]];
    //每个版本随机数会沿用，分组会重新计算
    NSDictionary *randomDic = [self.localStorageManager randomNumber] ?: [NSDictionary dictionary];
    NSMutableString *abGroup = [NSMutableString string];
    for (NSString *layerName in self.clientLayers) {
        BDClientABTestLayer *layer = [self.clientLayers objectForKey:layerName];
        //根据filter进行验证，未通过验证，则该层不参与试验
        BOOL passVerify = [self _isPassLayerFiltersVerify:layer];
        if (!passVerify) {
            [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB layer named %@ did not pass verify.",layerName]];
            continue;
        }
        //优先沿用之前的随机数，没有的话则生成
        NSNumber *randomNumber = [randomDic objectForKey:layer.name];
        if (![randomNumber isKindOfClass:[NSNumber class]]) {
            randomNumber = @([BDClientABManagerUtil genARandomNumber]);
            [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB layer named %@ generated a new randomNumber %ld.",layerName,[randomNumber integerValue]]];
        } else {
            [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB layer named %@ using cached randomNumber %ld.",layerName,[randomNumber integerValue]]];
        }
        [newRandomDic setObject:randomNumber forKey:layer.name];
        for (BDClientABTestGroup *group in layer.groups) {
            if (group.minRegion <= [randomNumber integerValue] && group.maxRegion >= [randomNumber integerValue]) {
                //命中此组
                [newLayer2GroupMap setObject:group.name forKey:layer.name];
                [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB layer %@ settle on group %@.",layerName,group.name]];
                [newFeatureDic addEntriesFromDictionary:group.results];
                [abGroup appendFormat:@"%@,",group.name];
                break;
            }
        }
    }
    [self.localStorageManager saveRandomNumberDicts:newRandomDic];
    [self.localStorageManager saveCurrentVersionLayer2GroupMap:newLayer2GroupMap];
    [self.localStorageManager resetFeatureKeys:newFeatureDic];
    if ([abGroup length] > 0) {
        [self.localStorageManager saveABGroup:[abGroup substringToIndex:[abGroup length] - 1]];
    }
    //标记此版本已经计算过
    self.appVersionStr = [BDClientABManagerUtil appVersion];
    [self.localStorageManager saveAppVersion:self.appVersionStr];
    [[BDABTestManager sharedManager] doLog:@"ClientAB finish caculating."];
    [self sendABClientLayer];
}

- (void)sendABClientLayer
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@"abtest_ab_sdk" forKey:@"params_for_special"];
    NSDictionary *layerIndexs = [self.localStorageManager randomNumber];
    [parameters setValue:layerIndexs forKey:@"client_layer_info"];
    [BDTrackerProtocol eventV3:@"local_strategy" params:parameters];
}

- (NSString *)ABGroup
{
    return [self.localStorageManager ABGroup];
}

- (NSString *)ABVersion
{
    return [self.localStorageManager ABVersion];
}

- (void)saveABVersion:(NSString *)abVersion
{
    [self.localStorageManager saveABVersion:abVersion];
}

- (void)saveServerSettingsForClientExperiments:(NSDictionary *)dict
{
    if (![dict isKindOfClass:[NSDictionary class]] || [dict count] == 0) {
        return;
    }

    NSMutableDictionary *changeDict = [NSMutableDictionary dictionaryWithCapacity:[dict count]];
    for (NSString * key in [dict allKeys]) {
        if (isEmptyString_forABManager(key)) {
            continue;
        }
        NSString * value = [dict objectForKey:key];
        if (isEmptyString_forABManager(value)) {
            continue;
        }
        [changeDict setObject:value forKey:key];
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB serverSetting change key %@ to value %@.",key,value]];
    }
    
    [_localStorageManager resetServerSettingFeatureKeys:dict];
}

- (id)valueForFeatureKey:(NSString *)featureKey
{
    return [_localStorageManager valueForFeatureKey:featureKey];
}

- (id)serverSettingValueForFeatureKey:(NSString *)featureKey
{
    return [_localStorageManager serverSettingValueForFeatureKey:featureKey];
}

- (NSNumber *)vidForLayerName:(NSString *)layerName
{
    NSString *groupName = [[self.localStorageManager currentLayer2GroupMap] objectForKey:layerName];
    if ([groupName isKindOfClass:[NSString class]] && [groupName length] > 0) {
        return [NSNumber numberWithInteger:[groupName integerValue]];
    }
    [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB did not find vid for layer named %@.",layerName]];
    return nil;
}

#pragma mark -- filter keys logic

/**
 *  判断是否通过了layer的filter验证
 *
 *  @param layer 待判断的layer
 *
 *  @return YES:通过,NO:未通过
 */
- (BOOL)_isPassLayerFiltersVerify:(BDClientABTestLayer *)layer
{
    BOOL isPass = [self _verifyChannelFilters:layer];
    if (!isPass) {
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB layer named %@ did not pass channel verify.",layer.name]];
        return NO;
    }
    isPass = [self _verifyFirstInstallVersion:layer];
    if (!isPass) {
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB layer named %@ did not pass firstInstallVersion verify.",layer.name]];
        return NO;
    }
    isPass = [self _verifyNormalFilterKeys:layer];
    if (!isPass) {
        [[BDABTestManager sharedManager] doLog:[NSString stringWithFormat:@"ClientAB layer named %@ did not pass normalFilter verify.",layer.name]];
        return NO;
    }
    return YES;
}

#define kBDClientABManagerLayerFilterKeyChannelKey @"channel"
#define kBDClientABManagerLayerFilterKeyChannelNegationKey @"!"
#define kBDClientABManagerLayerFilterKeyChannelSeparatorKey @","
/**
 *  验证channel的条件是否通过
 *
 *  @param layer 待验证的layer
 *
 *  @return YES：通过验证， NO：未通过验证
 */
- (BOOL)_verifyChannelFilters:(BDClientABTestLayer *)layer
{
    if ([[layer.filters allKeys] containsObject:kBDClientABManagerLayerFilterKeyChannelKey]) {
        
        NSString * filterChannel = [layer.filters objectForKey:kBDClientABManagerLayerFilterKeyChannelKey];
        
        if (isEmptyString_forABManager(filterChannel)) {
            return YES;
        }
        NSString * appChannel = [BDClientABManagerUtil channelName];
        if (isEmptyString_forABManager(appChannel)) {
            [[BDABTestManager sharedManager] doLog:@"warning: can not get the channel of app"];
            return YES;
        }
        
        BOOL isNegation = [filterChannel hasPrefix:kBDClientABManagerLayerFilterKeyChannelNegationKey];
        
        if (isNegation) { //!开头
            NSString * noNegationChannelStr = [filterChannel substringFromIndex:[kBDClientABManagerLayerFilterKeyChannelNegationKey length]];
            if (isEmptyString_forABManager(noNegationChannelStr)) {
                [[BDABTestManager sharedManager] doLog:@"Error during filterChannel"];
                return YES;
            }
            NSArray<NSString *> * channelStrs = [noNegationChannelStr componentsSeparatedByString:kBDClientABManagerLayerFilterKeyChannelSeparatorKey];
            BOOL contain = [channelStrs containsObject:appChannel];
            return !contain;
        } else {//看当前app 的渠道是否在自定的渠道中
            NSArray<NSString *> * channelStrs = [filterChannel componentsSeparatedByString:kBDClientABManagerLayerFilterKeyChannelSeparatorKey];
            BOOL contain = [channelStrs containsObject:appChannel];
            return contain;
        }
    } else {
        return YES;
    }
}

#define kBDClientABManagerLayerFilterKeyFirstInstallVersionKey @"first_install_version"

#define kBDClientABManagerLayerFilterKeyFirstInstallVersionLessKey @"<"
#define kBDClientABManagerLayerFilterKeyFirstInstallVersionGreateOrEqualKey @">="

- (BOOL)_verifyFirstInstallVersion:(BDClientABTestLayer *)layer
{
    NSString * versionFilter = [layer.filters objectForKey:kBDClientABManagerLayerFilterKeyFirstInstallVersionKey];
    if (isEmptyString_forABManager(versionFilter)) {
        return YES;
    }
    NSString * appFirstInstallVersion = [BDClientABStorageManager firstInstallVersionStr];
    if ([versionFilter hasPrefix:kBDClientABManagerLayerFilterKeyFirstInstallVersionGreateOrEqualKey]) {//x.x及之后的新用户(>=)
        
        NSString * ver = [versionFilter substringFromIndex:[kBDClientABManagerLayerFilterKeyFirstInstallVersionGreateOrEqualKey length]];
        if (isEmptyString_forABManager(ver)) {
            [[BDABTestManager sharedManager] doLog:@"Error during versionFilter"];
            return YES;
        }
        
        BDClientABVersionCompareType compareType = [BDClientABManagerUtil compareVersion:appFirstInstallVersion toVersion:ver];
        if (compareType == BDClientABVersionCompareTypeEqualTo ||
            compareType == BDClientABVersionCompareTypeGreateThan) {
            return YES;
        }
        return NO;
    } else if ([versionFilter hasPrefix:kBDClientABManagerLayerFilterKeyFirstInstallVersionLessKey]) {
        NSString * ver = [versionFilter substringFromIndex:[kBDClientABManagerLayerFilterKeyFirstInstallVersionLessKey length]];
        if (isEmptyString_forABManager(ver)) {
            [[BDABTestManager sharedManager] doLog:@"Error during versionFilter"];
            return YES;
        }
        BDClientABVersionCompareType compareType = [BDClientABManagerUtil compareVersion:appFirstInstallVersion toVersion:ver];
        if (compareType == BDClientABVersionCompareTypeLessThan) {
            return YES;
        }
        return NO;
    }
    [[BDABTestManager sharedManager] doLog:@"Error during versionFilter"];
    return YES;
}

- (BOOL)_verifyNormalFilterKeys:(BDClientABTestLayer *)layer
{
    __block BOOL result = YES;
    [layer.filters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        BOOL isSpecialFilterKeys =
        [key isEqualToString:kBDClientABManagerLayerFilterKeyChannelKey] ||
        [key isEqualToString:kBDClientABManagerLayerFilterKeyFirstInstallVersionKey];
        if (!isSpecialFilterKeys) {
            NSString * value = [NSString stringWithFormat:@"%@", [self.localStorageManager valueForFeatureKey:key]];
            NSString * layerFilterValue = [NSString stringWithFormat:@"%@", [layer.filters objectForKey:key]];
            if (!isEmptyString_forABManager(layerFilterValue)) {
                if (![value isEqualToString:layerFilterValue]) {
                    result = NO;
                    *stop = YES;
                    return;
                }
            }
        }
    }];
    return result;
}

- (NSArray *)vidList
{
    return [self.localStorageManager vidList];
}

@end

//
//  BDPModel.m
//  Timor
//
//  Created by liubo on 2018/11/15.
//

#import "BDPModel.h"
#import "BDPSchemaCodec.h"
#import "BDPUniqueID.h"
#import "BDPUtils.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import "TMASecurity.h"
#import <OPFoundation/OPFoundation-Swift.h>

#import "BDPModel+H5Gadget.h"
#import "BDPModel+Private.h"
#import "EEFeatureGating.h"

#pragma mark - BDPModel

//@interface BDPModel()
//@property (nonatomic, strong, readwrite) id<AppMetaPackageProtocol> package;
//@property (nonatomic, copy, readwrite, nullable) NSString *appVersion; //当前小程序的应用版本【仅关于页展示使用】
//@end

@implementation BDPModel

#pragma mark - Init

- (instancetype)initWithDictionary:(NSDictionary *)dic
              uniqueID:(BDPUniqueID *)uniqueID
                           withKey:(NSString *)key
                               vec:(NSString *)iv {
    // 即将删除的代码，请不要再新增逻辑
    NSAssert(NO, @"BDPModel.initWithDictionary should not be called!!!");
    if (BDPIsEmptyDictionary(dic)) {
        return nil;
    }
    if (self = [super init]) {
        NSString *appID = [dic bdp_stringValueForKey:@"appid"] ?: [dic bdp_stringValueForKey:@"id"];
        if (![uniqueID.appID isEqualToString:appID]) {
            NSAssert(NO, @"appID in data should be same with the uniqueID!!!");
        }
        _uniqueID = uniqueID;
        _name = [dic bdp_stringValueForKey:@"name"];
        _icon = [dic bdp_stringValueForKey:@"icon"];
        // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
        _components = [dic bdp_arrayValueForKey:@"components"];
        _state = [dic bdp_integerValueForKey:@"state"];
        _versionState = [dic bdp_intValueForKey:@"version_state"];
        _authList = nil;
        _blackList = nil;
        _gadgetSafeUrls = [dic bdp_arrayValueForKey:@"gadgetSafeUrls"];
        _versionUpdateTime = [dic bdp_longlongValueForKey:@"version_update_time"];
        _shareLevel = [dic bdp_integerValueForKey:@"share_level"];
        _version = [dic bdp_stringValueForKey:@"version"];
        _appVersion = [dic bdp_stringValueForKey:@"appVersion"];
        _compileVersion = [dic bdp_stringValueForKey:@"compile_version"];
        _version_code = [dic bdp_longlongValueForKey:@"version_code"];
        _urls = [[self class] urlFromStrings:[dic bdp_arrayValueForKey:@"path"]];
        _pkgName = [_urls.firstObject.path bdp_fileName];
        _domainsAuthDict = nil;
        _minJSsdkVersion = [dic bdp_stringValueForKey:@"min_jssdk"];
        _abilityForMessageAction = [dic bdp_boolValueForKey:@"message_action"];
        _abilityForChatAction = [dic bdp_boolValueForKey:@"chat_action"];
        _webURL = [dic bdp_stringValueForKey:@"web_url"];
        _extraDict = nil;

        //处理加密字段
        if ([key length] > 0 && [iv length] > 0) {
            NSString *ttcode = [dic bdp_stringValueForKey:@"ttcode"];
            NSString *ttblackcode = [dic bdp_stringValueForKey:@"ttblackcode"];
            NSString *md5code = [dic bdp_stringValueForKey:@"md5"];
            NSData *decrypt = [ttcode tma_aesDecrypt:key iv:iv];
            NSData *blackcodeDecrypt = [ttblackcode tma_aesDecrypt:key iv:iv];
            NSData *md5Decrypt = [md5code tma_aesDecrypt:key iv:iv];
            NSArray *authList = [decrypt JSONValue];
            NSArray *blackList = [blackcodeDecrypt JSONValue];
            _authList = [authList isKindOfClass:[NSArray class]]? authList: nil;
            _blackList = [blackList isKindOfClass:[NSArray class]]? blackList: nil;
            _md5 = [[NSString alloc] initWithData:md5Decrypt encoding:NSUTF8StringEncoding];
            
            NSString *domains = [dic bdp_stringValueForKey:@"domains"];
            if (domains.length > 0) {
                NSDictionary *domainsDict = [[domains tma_aesDecrypt:key iv:iv] JSONValue];
                _domainsAuthDict = [domainsDict isKindOfClass:[NSDictionary class]] ? domainsDict : nil;
            }
            
            NSString *extra = [dic bdp_stringValueForKey:@"extra"];
            if (extra.length > 0) {
                NSDictionary *extraDict = [[extra tma_aesDecrypt:key iv:iv] JSONValue];
                _extraDict = [extraDict isKindOfClass:[NSDictionary class]] ? extraDict : nil;
            }
        }
        _md5 = _md5.length ? _md5 : @"-1"; //若为空, 说明被篡改或后台错误, 给个-1自然校验不过
    }
    return self;
}

/// 从GadgetMeta转换为BDPModel
/// @param gadgetMeta 小程序 H5小程序统一的Meta
//- (instancetype)initWithGadgetMeta:(GadgetMeta *)gadgetMeta {
//    BDPModel *model = BDPModel.new;
//    model.uniqueID = gadgetMeta.uniqueID;
//    model.name = gadgetMeta.name;
//    model.pkgName = [gadgetMeta.packageData.urls.firstObject.path bdp_fileName];
//    model.icon = gadgetMeta.iconUrl;
//    GadgetMetaAuth *auth = gadgetMeta.authData;
//    model.state = auth.appStatus;
//    model.versionState = auth.versionState;
//    model.authList = !BDPIsEmptyArray(auth.authList) ? auth.authList : nil;
//    model.blackList = !BDPIsEmptyArray(auth.blackList) ? auth.blackList : nil;
//    model.gadgetSafeUrls = !BDPIsEmptyArray(auth.gadgetSafeUrls) ? auth.gadgetSafeUrls : nil;
//    model.versionUpdateTime = auth.versionUpdateTime;
//    GadgetBusinessData *buz = gadgetMeta.businessData;
//    model.shareLevel = buz.shareLevel;
//    model.version = gadgetMeta.version;
//    model.appVersion = gadgetMeta.appVersion;
//    model.compileVersion = gadgetMeta.compileVersion;
//    model.version_code = buz.versionCode;
//    model.urls = gadgetMeta.packageData.urls;
//    model.md5 = gadgetMeta.packageData.md5;
//    model.domainsAuthDict = !BDPIsEmptyDictionary(auth.domainsAuthDict) ? auth.domainsAuthDict : nil;
//    model.minJSsdkVersion = buz.minJSsdkVersion;
//    model.minLarkVersion = buz.minLarkVersion;
//    model.abilityForMessageAction = buz.abilityForMessageAction;
//    model.abilityForChatAction = buz.abilityForChatAction;
//    model.extraDict = !BDPIsEmptyDictionary(buz.extraDict) ? buz.extraDict : nil;
//    model.webURL = !BDPIsEmptyString(buz.webURL) ? buz.webURL : nil;
//    // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
//    model.components = gadgetMeta.components;
//    model.package = gadgetMeta.packageData;
//
//    // 真机调试 socket_address 从 meta 中获取 https://bytedance.feishu.cn/docx/doxcnrF65AwjVNqFZxBvP70aRof
//    model.realMachineDebugSocketAddress = buz.realMachineDebugSocketAddress;
//    return model;
//}

+ (instancetype)fakeModelWithUniqueID:(BDPUniqueID *)uniqueID
                                             name:(NSString *)name
                                             icon:(NSString *)icon
                                             urls:(NSArray<NSURL *> *)urls {
    BDPModel *model = BDPModel.new;
    model.uniqueID = uniqueID;
    model.name = name;
    model.icon = icon;
    model.urls = urls;
    return model;
}

/// 转换为GadgetMeta workaround
//- (GadgetMeta *)toGadgetMeta {
//    NSMutableDictionary * packages = @{}.mutableCopy;
//    [self.package.subPackages enumerateObjectsUsingBlock:^(id<AppMetaSubPackageProtocol>  _Nonnull package, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSMutableDictionary * packageMap = @{}.mutableCopy;
//        NSMutableArray * paths = @[].mutableCopy;
//        for (NSURL * URL in package.urls) {
//            [paths addObject:URL.absoluteString];
//        }
//        packageMap[@"path"] = paths;
//        packageMap[@"pages"] = package.pages.copy;
//        packageMap[@"md5"] = package.md5;
//        packageMap[@"independent"] = @(package.isIndependent);
//        packages[package.isMainPackage ? GadgetSubPackage.kMainAppTag : package.path] = packageMap;
//    }];
//
//    NSDictionary *diffPath = nil;
//    if ([OPSDKFeatureGating packageIncremetalUpdateEnable]) {
//        // 获取包信息中的增量包信息
//        id packageData = (id)self.package;
//        if ([packageData respondsToSelector:@selector(conformsToProtocol:)] && [packageData conformsToProtocol:@protocol(AppMetaDiffPackageProtocol)]) {
//            diffPath = ((id<AppMetaDiffPackageProtocol>)packageData).diffPkgPath;
//        }
//    }
//
//    return [[GadgetMeta alloc]
//            initWithUniqueID:self.uniqueID
//            version:self.version ?: @""
//            appVersion:self.appVersion ?: @""
//            compileVersion:self.compileVersion ?: @""
//            name:self.name ?: @""
//            iconUrl:self.icon ?: @""
//            // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
//            components: self.components
//            packageData:[[GadgetMetaPackage alloc]
//                         initWithUrls:self.urls
//                         md5:self.md5
//                         packages:packages
//                         diffPkgPath: diffPath]
//            authData:[[GadgetMetaAuth alloc]
//                      initWithAppStatus:self.state
//                      versionState:self.versionState
//                      authList:self.authList ?: @[]
//                      blackList:self.blackList ?: @[]
//                      gadgetSafeUrls:self.gadgetSafeUrls ?: @[]
//                      domainsAuthDict:self.domainsAuthDict ?: @{}
//                      versionUpdateTime:self.versionUpdateTime]
//            businessData:[[GadgetBusinessData alloc]
//                          initWithExtraDict:self.extraDict ?: @{}
//                          shareLevel:self.shareLevel
//                          versionCode:self.version_code
//                          minJSsdkVersion:self.minJSsdkVersion ?: @""
//                          minLarkVersion:self.minLarkVersion ?: @""
//                          webURL:self.webURL ?: @""
//                          abilityForMessageAction:self.abilityForMessageAction
//                          abilityForChatAction:self.abilityForChatAction
//                          isFromBuildin:NO
//                          realMachineDebugSocketAddress:self.realMachineDebugSocketAddress]];
//}

- (BOOL)offline {
    return _state == BDPAppStatusDisable;
}

#pragma mark - Interface
+ (NSArray<NSURL *> *)urlFromStrings:(NSArray<NSString *> *)urlStrings {
    NSArray *requestURLs = nil;
    if (urlStrings.count) {
        NSMutableArray *urls = [NSMutableArray arrayWithCapacity:urlStrings.count];
        for (NSString *urlString in urlStrings) {
            NSURL *url = [NSURL URLWithString:urlString];
            if (url) {
                [urls addObject:url];
            }
        }
        requestURLs = [urls copy];
    }
    return requestURLs;
}

- (BOOL)isNewerThanAppModel:(BDPModel *)model {
    BDPLogInfo(@"model:self ID(%@:%@) version_code(%@:%@), md5(%@:%@), version(%@:%@)", model.uniqueID, self.uniqueID, @(model.version_code), @(self.version_code), model.md5, self.md5, model.version, self.version);

    // TODO: yinyuan 需要确认如何处理
    if (![model.uniqueID.appID isEqualToString:self.uniqueID.appID]) {
        return NO;
    }
    if (![model.uniqueID.identifier isEqualToString:self.uniqueID.identifier]) {
        return NO;
    }
    // 20190703包更新条件变更需求修改
    BOOL hasUpdate =  model.version_code != self.version_code && ![model.md5 isEqualToString:self.md5] && ![OPFGBridge disableAppUpdateCheckWithMD5Verify];
    //收口判断是否有更新的方法（包MD5||包版本||应用版本三者其中一个有变化均提示更新）
    //https://bytedance.feishu.cn/docx/doxcntnJut77le3DSB5otE21dic
    if (BDPIsEmptyString(self.appVersion)) {
        //缓存的应用版本为空，需要检查包版本是否有变化。若不同则需要提示更新
        hasUpdate = hasUpdate || ![BDPSafeString(model.version) isEqualToString: self.version];
        BDPLogInfo(@"isNewerThanAppModel self.currentModel.appVersion is empty, has update: %@", @(hasUpdate));
        BDPLogInfo(@"isNewerThanAppModel model.version:%@, self.currentModel.version:%@", model.version, self.version);
    } else {
        //缓存的应用版本不为空，需要检查应用版本是否有变化。若不同则说明有更新
        hasUpdate = hasUpdate || ![BDPSafeString(model.appVersion) isEqualToString: self.appVersion] || ![BDPSafeString(model.version) isEqualToString: self.version];
        BDPLogInfo(@"isNewerThanAppModel self.currentModel.appVersion is not empty, has update: %@", @(hasUpdate));
        BDPLogInfo(@"isNewerThanAppModel model.appVersion:%@, self.currentModel.appVersion:%@", model.appVersion, self.appVersion);
    }
    return hasUpdate;
}

- (void)mergeNewestInfoFromModel:(BDPModel *)newestModel {
    // TODO: yinyuan 需要确认如何处理
    if (![newestModel.uniqueID.appID isEqualToString:self.uniqueID.appID]) {
        return;
    }
    if (![newestModel.uniqueID.identifier isEqualToString:self.uniqueID.identifier]) {
        return;
    }
    
    self.state = newestModel.state;
    self.versionState = newestModel.versionState;
    self.versionUpdateTime = newestModel.versionUpdateTime;
    self.authList = newestModel.authList;
    self.blackList = newestModel.blackList;
    self.shareLevel = newestModel.shareLevel;
    self.domainsAuthDict = newestModel.domainsAuthDict;
    self.extraDict = newestModel.extraDict;
    self.webURL = newestModel.webURL;
    if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWebComponentDoubleCheck]) {
        self.gadgetSafeUrls = newestModel.gadgetSafeUrls;
    }
    // 支持app名字国际化, getMeta异步更新的时候，需要更新App的名字
    self.name = newestModel.name;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    // 即将删除的代码，请不要再新增逻辑
    NSAssert(NO, @"BDPModel.initWithCoder should not be called!!!");
    if (self = [super init]) {
        NSString *appID = [aDecoder decodeObjectForKey:@"appid"];
        NSString *versionTypeString = [aDecoder decodeObjectForKey:@"versionType"];
        // 默认是 BDPTypeNativeApp, H5小程序应当在外部覆盖设置 uniqueID ，这里 uniqueID 只做兜底处理，后续会删除该逻辑
        self.uniqueID = [BDPUniqueID uniqueIDWithAppID:appID identifier:nil versionType:OPAppVersionTypeFromString(versionTypeString) appType:BDPTypeNativeApp];
        
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.pkgName = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(pkgName))];
        self.icon = [aDecoder decodeObjectForKey:@"icon"];
        self.state = [[aDecoder decodeObjectForKey:@"state"] integerValue];
        self.versionState = [[aDecoder decodeObjectForKey:@"version_state"] integerValue];
        self.authList = [aDecoder decodeObjectForKey:@"authlist"];
        self.blackList = [aDecoder decodeObjectForKey:@"blacklist"];
        self.shareLevel = [[aDecoder decodeObjectForKey:@"sharelevel"] integerValue];
        self.version = [aDecoder decodeObjectForKey:@"version"];
        self.appVersion = [aDecoder decodeObjectForKey:@"appVersion"];
        self.version_code = [aDecoder decodeInt64ForKey:NSStringFromSelector(@selector(version_code))];
        self.urls = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(urls))];
        self.md5 = [aDecoder decodeObjectForKey:@"md5"];
        self.domainsAuthDict = [aDecoder decodeObjectForKey:@"domainsauthdict"];
        self.minJSsdkVersion = [aDecoder decodeObjectForKey:@"minjssdkversion"];
        self.extraDict = [aDecoder decodeObjectForKey:@"extradict"];
        self.webURL = [aDecoder decodeObjectForKey:@"webUrl"];
        self.abilityForMessageAction = [aDecoder decodeBoolForKey:@"message_action"];
        self.abilityForChatAction = [aDecoder decodeBoolForKey:@"chat_action"];
        // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
        if ([aDecoder containsValueForKey:@"components"]) {
            self.components = [aDecoder decodeObjectForKey:@"components"];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    // 即将删除的代码，请不要再新增逻辑
    NSAssert(NO, @"BDPModel.encodeWithCoder should not be called!!!");
    [aCoder encodeObject:self.uniqueID.appID forKey:@"appid"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.pkgName forKey:NSStringFromSelector(@selector(pkgName))];
    [aCoder encodeObject:self.icon forKey:@"icon"];
    [aCoder encodeObject:@(self.state) forKey:@"state"];
    [aCoder encodeObject:@(self.versionState) forKey:@"version_state"];
    [aCoder encodeObject:self.authList forKey:@"authlist"];
    [aCoder encodeObject:self.blackList forKey:@"blacklist"];
    [aCoder encodeObject:@(self.shareLevel) forKey:@"sharelevel"];
    [aCoder encodeObject:self.version forKey:@"version"];
    [aCoder encodeObject:self.appVersion forKey:@"appVersion"];
    [aCoder encodeInt64:self.version_code forKey:NSStringFromSelector(@selector(version_code))];
    [aCoder encodeObject:self.urls forKey:NSStringFromSelector(@selector(urls))];
    [aCoder encodeObject:self.md5 forKey:@"md5"];
    [aCoder encodeObject:self.domainsAuthDict forKey:@"domainsauthdict"];
    [aCoder encodeObject:self.minJSsdkVersion forKey:@"minjssdkversion"];
    [aCoder encodeObject:self.extraDict forKey:@"extradict"];
    [aCoder encodeObject:OPAppVersionTypeToString(self.uniqueID.versionType) forKey:@"versionType"];
    [aCoder encodeObject:self.webURL forKey:@"webUrl"];
    [aCoder encodeBool:self.abilityForMessageAction forKey:@"message_action"];
    [aCoder encodeBool:self.abilityForChatAction forKey:@"chat_action"];
    // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
     if (self.components) {
        [aCoder encodeObject:self.components forKey:@"components"];
     }
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    BDPModel *model = [[BDPModel alloc] init];
    model.uniqueID = self.uniqueID;
    model.name = self.name;
    model.pkgName = self.pkgName;
    model.icon = self.icon;
    model.state = self.state;
    model.versionState = self.versionState;
    model.authList = self.authList;
    model.blackList = self.blackList;
    model.shareLevel = self.shareLevel;
    model.version = self.version;
    model.appVersion = self.appVersion;
    model.version_code = self.version_code;
    model.urls = self.urls;
    model.md5 = self.md5;
    model.domainsAuthDict = self.domainsAuthDict;
    model.minJSsdkVersion = self.minJSsdkVersion;
    model.minLarkVersion = self.minLarkVersion;
    model.extraDict = self.extraDict;
    model.webURL = self.webURL;
    model.uniqueID = self.uniqueID;
    model.abilityForChatAction = self.abilityForChatAction;
    model.abilityForMessageAction = self.abilityForMessageAction;
    // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
    model.components = self.components;
    return model;
}

#pragma mark - Override

- (BOOL)isEqual:(BDPModel *)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[BDPModel class]]) return NO;
    // TODO: yinyuan 这里如何判等需要确认解决
    return [object.uniqueID.appID isEqualToString:self.uniqueID.appID] && [object.uniqueID.identifier isEqualToString:self.uniqueID.identifier] && [object.pkgName isEqualToString:object.pkgName];
}

- (NSUInteger)hash {
    return self.uniqueID.appID.hash ^ self.uniqueID.identifier.hash ^ self.pkgName.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"BDPModel:{ID:%@; Name:%@; Ver:%@; State:%ld;}", self.uniqueID, self.name, self.version, (long)self.state];
}

#pragma mark - Utility

- (NSString *)fullVersionDescription {
    // 即将删除的代码，请不要再新增逻辑
    NSAssert(NO, @"BDPModel.fullVersionDescription should not be called!!!");
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.uniqueID.fullString forKey:@"uniqueID"];
    [dic setValue:self.name forKey:@"name"];
    [dic setValue:self.icon forKey:@"icon"];
    // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
    [dic setValue:self.components forKey:@"components"];
    [dic setValue:@(self.state) forKey:@"state"];
    [dic setValue:@(self.versionState) forKey:@"version_state"];
    [dic setValue:[self.authList copy] forKey:@"auth"];
    [dic setValue:[self.blackList copy] forKey:@"black"];
    [dic setValue:@(self.shareLevel) forKey:@"share"];
    [dic setValue:self.version forKey:@"ver"];
    [dic setValue:self.md5 forKey:@"md5"];
    [dic setValue:[self.domainsAuthDict copy] forKey:@"domains"];
    [dic setValue:self.minJSsdkVersion forKey:@"minjs"];
    [dic setValue:[self.extraDict copy] forKey:@"extra"];
    dic[NSStringFromSelector(@selector(urls))] = ({
        NSMutableArray *urlStrs = [NSMutableArray arrayWithCapacity:self.urls.count];
        for (NSURL *url in self.urls) {
            [urlStrs addObject:url.absoluteString];
        }
        [urlStrs copy];
    });
    dic[NSStringFromSelector(@selector(pkgName))] = self.pkgName;
    return [NSString stringWithFormat:@"BDPModel:{%@}", [dic JSONRepresentation]];
}

/// 从 components 把 names 摘出来，方便外部使用
- (NSArray *)componentsNames {
    NSMutableArray *components = [[NSMutableArray alloc] init];
    [self.components enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull component, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *name = [component valueForKey:@"name"];
        if (name != nil) {
            [components addObject:name];
        }
    }];
    return [components copy];
}

@end

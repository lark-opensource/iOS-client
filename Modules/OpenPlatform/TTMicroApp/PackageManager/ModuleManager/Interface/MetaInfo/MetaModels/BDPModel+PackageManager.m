//
//  BDPModel+PackageManager.m
//  TTMicroApp
//
//  Created by justin on 2022/12/22.
//

#import "BDPModel+PackageManager.h"
#import <OPFoundation/BDPModel+H5Gadget.h>

#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

@implementation BDPModel (PackageManager)

/// 从GadgetMeta转换为BDPModel
/// @param gadgetMeta 小程序 H5小程序统一的Meta
- (instancetype)initWithGadgetMeta:(GadgetMeta *)gadgetMeta {
    BDPModel *model = BDPModel.new;
    model.uniqueID = gadgetMeta.uniqueID;
    model.name = gadgetMeta.name;
    model.pkgName = [gadgetMeta.packageData.urls.firstObject.path bdp_fileName];
    model.icon = gadgetMeta.iconUrl;
    GadgetMetaAuth *auth = gadgetMeta.authData;
    model.state = auth.appStatus;
    model.versionState = auth.versionState;
    model.authList = !BDPIsEmptyArray(auth.authList) ? auth.authList : nil;
    model.blackList = !BDPIsEmptyArray(auth.blackList) ? auth.blackList : nil;
    model.gadgetSafeUrls = !BDPIsEmptyArray(auth.gadgetSafeUrls) ? auth.gadgetSafeUrls : nil;
    model.versionUpdateTime = auth.versionUpdateTime;
    GadgetBusinessData *buz = gadgetMeta.businessData;
    model.shareLevel = buz.shareLevel;
    model.version = gadgetMeta.version;
    model.appVersion = gadgetMeta.appVersion;
    model.compileVersion = gadgetMeta.compileVersion;
    model.version_code = buz.versionCode;
    model.urls = gadgetMeta.packageData.urls;
    model.md5 = gadgetMeta.packageData.md5;
    model.domainsAuthDict = !BDPIsEmptyDictionary(auth.domainsAuthDict) ? auth.domainsAuthDict : nil;
    model.minJSsdkVersion = buz.minJSsdkVersion;
    model.minLarkVersion = buz.minLarkVersion;
    model.abilityForMessageAction = buz.abilityForMessageAction;
    model.abilityForChatAction = buz.abilityForChatAction;
    model.extraDict = !BDPIsEmptyDictionary(buz.extraDict) ? buz.extraDict : nil;
    model.webURL = !BDPIsEmptyString(buz.webURL) ? buz.webURL : nil;
    // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
    model.components = gadgetMeta.components;
    model.package = gadgetMeta.packageData;

    // 真机调试 socket_address 从 meta 中获取 https://bytedance.feishu.cn/docx/doxcnrF65AwjVNqFZxBvP70aRof
    model.realMachineDebugSocketAddress = buz.realMachineDebugSocketAddress;
    model.performanceProfileAddress = buz.performanceProfileAddress;
    return model;
}

/// 转换为GadgetMeta workaround
- (GadgetMeta *)toGadgetMeta {
    NSMutableDictionary * packages = @{}.mutableCopy;
    [self.package.subPackages enumerateObjectsUsingBlock:^(id<AppMetaSubPackageProtocol>  _Nonnull package, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary * packageMap = @{}.mutableCopy;
        NSMutableArray * paths = @[].mutableCopy;
        for (NSURL * URL in package.urls) {
            [paths addObject:URL.absoluteString];
        }
        packageMap[@"path"] = paths;
        packageMap[@"pages"] = package.pages.copy;
        packageMap[@"md5"] = package.md5;
        packageMap[@"independent"] = @(package.isIndependent);
        packages[package.isMainPackage ? GadgetSubPackage.kMainAppTag : package.path] = packageMap;
    }];

    NSDictionary *diffPath = nil;
    if ([OPSDKFeatureGating packageIncremetalUpdateEnable]) {
        // 获取包信息中的增量包信息
        id packageData = (id)self.package;
        if ([packageData respondsToSelector:@selector(conformsToProtocol:)] && [packageData conformsToProtocol:@protocol(AppMetaDiffPackageProtocol)]) {
            diffPath = ((id<AppMetaDiffPackageProtocol>)packageData).diffPkgPath;
        }
    }

    return [[GadgetMeta alloc]
            initWithUniqueID:self.uniqueID
            version:self.version ?: @""
            appVersion:self.appVersion ?: @""
            compileVersion:self.compileVersion ?: @""
            name:self.name ?: @""
            iconUrl:self.icon ?: @""
            // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
            components: self.components
            packageData:[[GadgetMetaPackage alloc]
                         initWithUrls:self.urls
                         md5:self.md5
                         packages:packages
                         diffPkgPath: diffPath]
            authData:[[GadgetMetaAuth alloc]
                      initWithAppStatus:self.state
                      versionState:self.versionState
                      authList:self.authList ?: @[]
                      blackList:self.blackList ?: @[]
                      gadgetSafeUrls:self.gadgetSafeUrls ?: @[]
                      domainsAuthDict:self.domainsAuthDict ?: @{}
                      versionUpdateTime:self.versionUpdateTime]
            businessData:[[GadgetBusinessData alloc]
                          initWithExtraDict:self.extraDict ?: @{}
                          shareLevel:self.shareLevel
                          versionCode:self.version_code
                          minJSsdkVersion:self.minJSsdkVersion ?: @""
                          minLarkVersion:self.minLarkVersion ?: @""
                          webURL:self.webURL ?: @""
                          abilityForMessageAction:self.abilityForMessageAction
                          abilityForChatAction:self.abilityForChatAction
                          isFromBuildin:NO
                          realMachineDebugSocketAddress:self.realMachineDebugSocketAddress
                          performanceProfileAddress:self.performanceProfileAddress]];
}

@end

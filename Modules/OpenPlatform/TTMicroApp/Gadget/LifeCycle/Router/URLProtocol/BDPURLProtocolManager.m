//
//  BDPURLProtocolManager.m
//  Timor
//
//  Created by CsoWhy on 2018/8/15.
//

#import "BDPURLProtocolManager.h"
#import "NSURLProtocol+BDPExtension.h"

#import <OPFoundation/BDPMacroUtils.h>
#import "BDPAppLoadURLInfo.h"
#import <OPFoundation/BDPWebpURLProtocol.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/BDPUtils.h>
#import "BDPURLProtocol.h"
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPSchemaCodec.h>
#import <ECOInfra/EMAFeatureGating.h>
#import <OPFoundation/BDPCommonManager.h>
#import <ECOProbeMeta/ECOProbeMeta-Swift.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

#define JSSDK_SCHEME_PREFIX BDP_JSSDK_SCHEME @":"
#define JSSDK_SCHEME_PREFIX_FULL JSSDK_SCHEME_PREFIX @"//"

#define PAGE_HTML_PARAM @"xj3s8ml9=1"
#define VIRTUAL_SCHEMA @"file"
#define VIRTUAL_BASE_FOLDER_PATH @"/bdpbase/"
#define VIRTUAL_FODLER_NAME @"bdpdir"

#define SEPARATOR @"/"

typedef struct _BDPVirtualPathInfo {
    BOOL isVirtualPath;
    BOOL isInJSSDK;
    /** 虚拟路径的范围, 不带末尾'/' */
    NSRange virtualPathRange;
    /** 相对路径 */
    NSRange relativePathRange;
} BDPVirtualPathInfo;

@interface BDPURLProtocolManager ()

@property (nonatomic, class, readonly) Class urlProtocolClass;

@property (nonatomic, readonly) NSArray<NSString *> *interceptSchemes;

// 用于实现文件路径和应用信息的关联
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *foldersDic;
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *copyFoldersDic;

@property (nonatomic, assign) NSInteger folderIndex;
@property (nonatomic, strong) dispatch_semaphore_t syncLock;

/// 虚拟路径: App沙盒路径/bdpbase/bdpdir/
@property (nonatomic, copy) NSString *virtualFolderPath;
/// 虚拟文件路径: file://App沙盒路径/bdpbase/bdpdir/
@property (nonatomic, copy) NSString *virtualFolderFilePath;
/// 虚拟文件路径: file://App沙盒路径/bdpbase/
@property (nonatomic, copy) NSString *virtualBaseFolderFilePath;

@end

@implementation BDPURLProtocolManager

#pragma mark - Initialize
static BDPURLProtocolManager *manager;
+ (instancetype)sharedManager
{
    @synchronized (self) {
        if (!manager) {
            manager = [[BDPURLProtocolManager alloc] init];
            manager.syncLock = dispatch_semaphore_create(1);
        }
    }
    return manager;
}

+ (void)clearSharedInstance {
    @synchronized (self) {
        manager = nil;
    }
    [BDPURLProtocol resetInfoCache];
}

- (instancetype)init {
    if (self = [super init]) {
        BDPResolveModule(storageModule, BDPStorageModuleProtocol, BDPTypeNativeApp);
        _virtualFolderPath = [NSString stringWithFormat:@"%@%@%@/", [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeBase], VIRTUAL_BASE_FOLDER_PATH, VIRTUAL_FODLER_NAME];
        _virtualFolderFilePath = [NSString stringWithFormat:@"%@://%@", VIRTUAL_SCHEMA, _virtualFolderPath];
        _virtualBaseFolderFilePath = [NSString stringWithFormat:@"%@://%@%@", VIRTUAL_SCHEMA, [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeBase], VIRTUAL_BASE_FOLDER_PATH];
        _disableProtocolLog = [OPSDKFeatureGating disableProtocolLog];
    }
    return self;
}

+ (Class)urlProtocolClass {
    return NSClassFromString(@"BDPURLProtocol");
}

+ (void)unregisterWKSchemas
{
    // 为了不影响其他业务方的代码逻辑，只取消注册http 和 https。
    [NSURLProtocol bdp_unregisterScheme:@"http"];
    [NSURLProtocol bdp_unregisterScheme:@"https"];
}

#pragma mark - REFERER
+ (NSString *)serviceReferer:(BDPUniqueID *)uniqueID version:(NSString *)version {
    // TODO: 确认这里是否可以通过参数的方式携带完整的 UniqueID 信息
    NSString *referer = [NSString stringWithFormat:@"%@/?appid=%@&version=%@", BDPSDKConfig.sharedConfig.serviceRefererURL, uniqueID.appID ?: @"", version ?: @""];
    return referer;
}

#pragma mark - 路径处理
- (nullable BDPAppLoadURLInfo *)infoOfRequest:(NSURLRequest *)request {
    NSURL *aURL = request.URL;
    if (aURL) {
        if (![self.interceptSchemes containsObject:aURL.scheme]) {
            return nil;
        }
        
        BDPVirtualPathInfo pathInfo = [self virtualPathInfoFromURL:aURL];
        if (pathInfo.isVirtualPath || pathInfo.isInJSSDK) { // 虚拟目录 或 在jssdk的路径
            NSString *urlStr = aURL.absoluteString;
            
            BDPAppLoadURLInfo *urlInfo = [[BDPAppLoadURLInfo alloc] init];
            urlInfo.requestURL = aURL;
            urlInfo.folder = pathInfo.isInJSSDK ? BDPAccessFolderJSSDK : BDPAccessFolderTTPKG;
            urlInfo.uniqueID = [BDPAppLoadURLInfo parseUniqueIDFromURLRequest:request];
            if (!pathInfo.isInJSSDK) { // 不在jssdk的取出appId, 和pkgName
                if (NSMaxRange(pathInfo.virtualPathRange) <= urlStr.length) {
                    NSString *virtualPath = [urlStr substringWithRange:pathInfo.virtualPathRange] ?: @"";
                    NSArray *appIdAndPkgName = [self.copyFoldersDic[virtualPath] componentsSeparatedByString:SEPARATOR];
                    if (appIdAndPkgName.count > 1) {
                        urlInfo.appID = appIdAndPkgName[0];
                        urlInfo.pkgName = appIdAndPkgName[1];
                    } else {
                        return nil;
                    }
                } else {
                    return nil;
                }
            }
            if (NSMaxRange(pathInfo.relativePathRange) <= urlStr.length) {
                urlInfo.realPath = [urlStr substringWithRange:pathInfo.relativePathRange];
                if (!urlInfo.realPath.length) {
                    return nil;
                }
            }
            return urlInfo;
        } else if ([aURL.scheme isEqualToString:BDP_TTFILE_SCHEME]) { // ttfile支持
            return [self ttFileInfoWithRequest:request];
        } else if ([aURL.scheme isEqualToString:VIRTUAL_SCHEMA]) { // 非虚拟目录的file协议老逻辑
            return [self localFileInfoWithRequest:request];
        }
    }
    return nil;
}

/// 先改造为收敛的标准化 FileSystem 沙箱文件操作，长期需要考虑将 BDPURLProtocol 的处理改造为 WebView custom scheme。
- (BDPAppLoadURLInfo *)ttFileInfoWithRequest:(NSURLRequest *)request {
    NSURL *aURL = request.URL;
    if (![aURL.scheme isEqualToString:BDP_TTFILE_SCHEME]) {
        return nil;
    }
    BDPAppLoadURLInfo *fileInfo = [[BDPAppLoadURLInfo alloc] init];
    OPAppUniqueID *uniqueId = [BDPAppLoadURLInfo parseUniqueIDFromURLRequest:request];
    fileInfo.uniqueID = uniqueId;
    NSURLComponents *comp = [[NSURLComponents alloc] initWithURL:aURL resolvingAgainstBaseURL:YES];

    /// 标准化文件操作收敛后不需要再解析参数了
    if (![OPFileSystemUtils isEnableStandardFeature:@"BDPURLProtocol"]) {
        for (NSURLQueryItem *item in comp.queryItems) {
            if ([item.name isEqualToString:BDP_PKG_AID_PARAM]) {
                fileInfo.appID = item.value;
            } else if ([item.name isEqualToString:BDP_PKG_NAME_PARAM]) {
                fileInfo.pkgName = item.value;
            }
        }
    }

    /// 有些业务 case，不一定会带上 _aid_ 与 _pkg_ 参数，如果uniqueId已经解析，应当直接兼容，否则会在下面返回 nil
    if ([EMAFeatureGating staticBoolValueForKey:@"ecosystem.bdp.urlprotocol.ua.compatible"]) {
        if (fileInfo.uniqueID) {
            fileInfo.appID = fileInfo.uniqueID.appID;
            BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:fileInfo.uniqueID];
            if (common) {
                fileInfo.pkgName = common.model.pkgName;
            }
        }

        /// 让我们来看看有哪些 url 不能从 UA 解析，为将来的改造做准备
        if (!fileInfo.uniqueID) {
            OPMonitorEvent *event = [[OPMonitorEvent alloc] initWithService:nil
                                                                       name:nil
                                                                monitorCode:EPMClientOpenPlatformInfraFileSystemCode.open_app_webview_ua_resolve_fail];
            event
                .addCategoryValue(kEventKey_app_id, fileInfo.appID) // 如果有就带上
                .addCategoryValue(@"url_scheme", aURL.scheme)
                .addCategoryValue(@"url_host", aURL.host)
                .addCategoryValue(@"url_path", [aURL.path maskWithExcept:@":/-_."])
                .addCategoryValue(@"params_count", @(comp.queryItems.count))
                .flush();
        }
    }

    comp.query = nil;
    fileInfo.requestURL = comp.URL;
    if ([OPFileSystemUtils isEnableStandardFeature:@"BDPURLProtocol"]) {
        OPFileObject *fileObj = [[OPFileObject alloc] initWithRawValue:comp.URL.absoluteString];
        if (!fileObj || !uniqueId) {
            return nil;
        }
        OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:uniqueId trace:nil tag:@"BDPURLProtocol"];
        if (!fileObj.isValidSandboxFilePath) {
            fsContext.trace.error(@"file object is not valid sandbox file path, \"%@\"", fileObj.rawValue);
            return nil;
        }

        fileInfo.folder = BDPAccessFolderSandBox;
        NSError *error = nil;
        NSString *systemFilePath = [OPFileSystemCompatible getSystemFileFrom:fileObj context:fsContext error:&error];
        if (error) {
            fsContext.trace.error(@"getSystemFileFrom failed, hasSystemFilePath: %@, error: %@", @(systemFilePath != nil), error.description);
            return nil;
        }
        fileInfo.realPath = systemFilePath;
    } else {
        if (BDPIsEmptyString(fileInfo.appID) || !fileInfo.pkgName) {
            return nil;
        }

        NSString *rPath = fileInfo.requestURL.absoluteString;
        NSRange range = {0, 0};
        // 目前的小程序本地文件存储并没有适配 versionType 和 appType，这里按照默认情况构造
        OPAppUniqueID *uniqueID = fileInfo.uniqueID ?: [OPAppUniqueID uniqueIDWithAppID:fileInfo.appID identifier:nil versionType:OPAppVersionTypeCurrent appType:OPAppTypeGadget];
        BDPResolveModule(storageModule, BDPStorageModuleProtocol, BDPTypeNativeApp);
        if ((range = [self rangeForRootDirectory:APP_TEMP_DIR_NAME forRPath:rPath]).location != NSNotFound  && NSMaxRange(range) + 1 < rPath.length) { // temp
            fileInfo.folder = BDPAccessFolderSandBox;
            rPath = [rPath substringFromIndex:NSMaxRange(range)];
            NSString *tmpPath = [[storageModule sharedLocalFileManager] appTempPathWithUniqueID:uniqueID];
            fileInfo.realPath = [[NSString stringWithFormat:@"%@/%@", tmpPath, rPath] stringByStandardizingPath];
        } else if ((range = [self rangeForRootDirectory:APP_USER_DIR_NAME forRPath:rPath]).location != NSNotFound  && NSMaxRange(range) + 1 < rPath.length) { // user
            fileInfo.folder = BDPAccessFolderSandBox;
            rPath = [rPath substringFromIndex:NSMaxRange(range)];
            NSString *sandboxPath = [[storageModule sharedLocalFileManager] appSandboxPathWithUniqueID:uniqueID];
            fileInfo.realPath = [[NSString stringWithFormat:@"%@/%@", sandboxPath, rPath] stringByStandardizingPath];
        } else { // ttpkg
            fileInfo.folder = BDPAccessFolderTTPKG;
            if ([rPath hasPrefix:BDP_TTFILE_SCHEME]) {
                fileInfo.realPath = [rPath bdp_urlWithoutScheme];
            } else {
                fileInfo.realPath = rPath;
            }
        }
    }
    return fileInfo;
}

- (NSRange)rangeForRootDirectory:(NSString *)directory forRPath:(NSString *)rPath
{
    NSString *pattern = [NSString stringWithFormat:@"%@:/*%@/", BDP_TTFILE_SCHEME, directory];
    NSRange range = [rPath rangeOfString:pattern options:NSRegularExpressionSearch | NSCaseInsensitiveSearch];
    return range;
}

- (BDPAppLoadURLInfo *)localFileInfoWithRequest:(NSURLRequest *)request {
    NSURL *aURL = request.URL;
    NSString *appFolderPath = [[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeApp];
    NSString *urlPath = aURL.path;
    NSInteger fIndex = 0;
    NSInteger uIndex = 0;
    while (fIndex < appFolderPath.length
           && uIndex < urlPath.length
           && [appFolderPath characterAtIndex:fIndex] == [urlPath characterAtIndex:uIndex]) {
        fIndex++;
        uIndex++;
    }
    if (uIndex == appFolderPath.length) { // 路径为app下的
        BDPAppLoadURLInfo *info = [[BDPAppLoadURLInfo alloc] init];
        info.requestURL = aURL;
        info.uniqueID = [BDPAppLoadURLInfo parseUniqueIDFromURLRequest:request];
        NSString *appId = [self nextPathComponentFromIndex:&uIndex
                                                     inUrl:urlPath];
        if (appId.length) {
            info.appID = appId;
            NSString *component = [self nextPathComponentFromIndex:&uIndex
                                                             inUrl:urlPath];
            if (![component isEqualToString:BDP_APP_TMP_FOLDER_NAME]
                && ![component isEqualToString:BDP_APP_SANDBOX_FOLDER_NAME]
                && component.length) {
                info.pkgName = component;
                // uIndex位于'/', 取分隔符后1位作为起点
                if (uIndex < urlPath.length-1) {
                    info.realPath = [urlPath substringFromIndex:++uIndex];
                    return info;
                }
            }
        }
    }
    return nil;
}

- (BDPVirtualPathInfo)virtualPathInfoFromURL:(NSURL *)aURL {
    BOOL isVirtualPath = NO;
    BOOL isInJSSDK = NO;
    NSRange virtualPathRange = NSMakeRange(0, 0);
    NSRange relativePathRange = NSMakeRange(0, 0);
    
    const unichar kSeparator = '/';
    NSString *urlStr = aURL.absoluteString;
    if ([urlStr hasPrefix:_virtualBaseFolderFilePath]) { // 虚拟base目录路径解析
        const unichar kHash = '#';
        const unichar kQuestion = '?';
        
        isVirtualPath = YES;
        NSInteger index = _virtualBaseFolderFilePath.length;
        while (index < urlStr.length && [urlStr characterAtIndex:index] != kSeparator) { // 移到二级目录
            index++;
        }
        if (index < urlStr.length && [urlStr characterAtIndex:index] == kSeparator) {
            NSString *secondFolder = [urlStr substringWithRange:NSMakeRange(_virtualBaseFolderFilePath.length, index - _virtualBaseFolderFilePath.length)];
            index++; // 跳过'/'
            if ([secondFolder isEqualToString:BDP_JSLIB_FOLDER_NAME]) { // __dev__
                isInJSSDK = YES;
                relativePathRange = NSMakeRange(index, urlStr.length - index); // 取剩余即可
            } else if ([secondFolder isEqualToString:VIRTUAL_FODLER_NAME]) { // bdpdir
                while (index < urlStr.length && [urlStr characterAtIndex:index] != kSeparator) {
                    index++; // 跳过folderIndex
                }
                if (index < urlStr.length && [urlStr characterAtIndex:index] == kSeparator) {
                    virtualPathRange = NSMakeRange(0, index);
                    NSInteger rIndex = index + 1; // 相对路径起始取 '/' 后一位
                    while (rIndex < urlStr.length) {
                        unichar c = [urlStr characterAtIndex:rIndex];
                        if (c == kQuestion || c == kHash) { // '?' 或 '#' 提前结束
                            break;
                        }
                        rIndex++;
                    }
                    if (rIndex > index + 1) { // 有真实路径
                        relativePathRange = NSMakeRange(index + 1, rIndex - index - 1);
                    }
                    isInJSSDK = aURL.query.length && ([aURL.query containsString:BDP_JSSDK_MASK] || [aURL.query containsString:PAGE_HTML_PARAM]);
                }
            }
        }
    } else if ([urlStr hasPrefix:BDP_JSSDK_SCHEME]) {
        const unichar kColon = ':';
        
        isInJSSDK = YES;
        NSInteger index = BDP_JSSDK_SCHEME.length;
        if (index < urlStr.length && [urlStr characterAtIndex:index++] == kColon) {
            if (index + 1 < urlStr.length
                && [urlStr characterAtIndex:index] == kSeparator
                && [urlStr characterAtIndex:index+1] == kSeparator) {
                index += 2; // 跳过 "//"
            }
        }
        
        relativePathRange = NSMakeRange(index, urlStr.length - index);
    }
    return (BDPVirtualPathInfo){isVirtualPath, isInJSSDK, virtualPathRange, relativePathRange};
}

- (NSString *)nextPathComponentFromIndex:(NSInteger *)index inUrl:(NSString *)url {
    const unichar kSeparator = '/';
    const unichar kUnderline = '_';
    if (*index < url.length) {
        if ([url characterAtIndex:*index] == kSeparator) { // '/'开始
            (*index)++;
        }
        NSInteger begin = *index;
        if (*index + 2 >= url.length || ([url characterAtIndex:(*index)++] == kUnderline && [url characterAtIndex:(*index)++] == kUnderline)) {
            return nil; // 非双下划线目录
        }
        while (*index < url.length && [url characterAtIndex:*index] != kSeparator) {
            (*index)++;
        }
        NSInteger length = *index - begin;
        if (length > 0) {
            return [url substringWithRange:NSMakeRange(begin, length)];
        }
    }
    return nil;
}

- (NSString *)generateVirtualFolderPath {
    NSInteger index = 0;
    LOCK(self.syncLock, {
        index = self.folderIndex++;
    });
    return [_virtualFolderFilePath stringByAppendingFormat:@"%@", @(index)];
}

- (NSString *)addJSSDKFolderMaskForPath:(NSString *)path {
    if (path.length) {
        if (![path containsString:@"?"]) {
            path = [path stringByAppendingString:@"?"];
        } else {
            path = [path stringByAppendingString:@"&"];
        }
        return [NSString stringWithFormat:@"%@%@", path, PAGE_HTML_PARAM];
    }
    return nil;
}

- (BOOL)isInVirtualFolderOfPath:(NSString *)path {
    return [path hasPrefix:_virtualFolderPath];
}

- (void)registerFolderPath:(NSString *)path forUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName {
    if (path.length && uniqueID.appID.length && pkgName.length) {
        LOCK(self.syncLock, {
            self.foldersDic[path] = [NSString stringWithFormat:@"%@%@%@", uniqueID.appID, SEPARATOR, pkgName];
        });
    }
}

- (void)unregisterFolderPath:(NSString *)path {
    if (path.length) {
        LOCK(self.syncLock, {
            self.foldersDic[path] = nil;
        });
    }
}

- (void)setInterceptionEnable:(BOOL)enable withWKWebview:(WKWebView *)webview {
    @synchronized (self) {
        if (_requestInterruptionEnabled != enable) {
            NSMutableArray *interceptSchemes = [self.interceptSchemes mutableCopy];
            [interceptSchemes addObjectsFromArray:@[BDP_WEBP_HTTP_SCHEMA, BDP_WEBP_HTTPS_SCHEMA]];
            if (enable) {
                [NSURLProtocol registerClass:[BDPURLProtocolManager urlProtocolClass]];
                [NSURLProtocol registerClass:[BDPWebpURLProtocol class]];
                [NSURLProtocol bdp_registerSchemes:interceptSchemes withWKWebview:webview];
            } else {
                [NSURLProtocol unregisterClass:[BDPURLProtocolManager urlProtocolClass]];
                [NSURLProtocol unregisterClass:[BDPWebpURLProtocol class]];
                [NSURLProtocol bdp_unregisterSchemes:interceptSchemes withWKWebview:webview];
            }
            _requestInterruptionEnabled = enable;
        }
    }
}

#pragma mark - Accessor
- (void)setRequestInterruptionEnabled:(BOOL)requestInterruptionEnabled {
    [self setInterceptionEnable:requestInterruptionEnabled withWKWebview:nil];
}

- (NSArray<NSString *> *)interceptSchemes {
    return @[
             VIRTUAL_SCHEMA,
             BDP_JSSDK_SCHEME,
             BDP_TTFILE_SCHEME,
             ];
}

- (NSDictionary<NSString *,NSString *> *)copyFoldersDic {
    NSDictionary *copyFoldersDic = nil;
    LOCK(self.syncLock, {
        copyFoldersDic = [self.foldersDic copy];
    });
    return copyFoldersDic;
}

#pragma mark LazyLoading
- (NSMutableDictionary<NSString *,NSString *> *)foldersDic {
    if (!_foldersDic) {
        _foldersDic = [[NSMutableDictionary<NSString *,NSString *> alloc] init];
    }
    return _foldersDic;
}

@end


//
//  BDPURLProtocol.m
//  Timor
//
//  Created by CsoWhy on 2018/8/17.
//

#import "BDPURLProtocol.h"
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUtils.h>
#import "BDPAppLoadManager+Util.h"
#import "BDPAppLoadURLInfo.h"
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import "BDPURLProtocolManager.h"
#import "BDPAppLoadDefineHeader.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>
#import <OPFoundation/BDPCommonManager.h>

#import "BDPTracker+BDPLoadService.h"

#import <OPSDK/OPSDK-Swift.h>
#import "BDPSubPackageManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPPkgFileBasicModel.h"
#import <LarkStorage/LarkStorage-Swift.h>

#define BDP_REQUEST_KEY @"com.bd.timor.BDPURLProtocol"

static NSCache *sInfoCache = nil;
static NSSet *sLogExetensions = nil;

@interface BDPURLProtocol ()

//@property (nonatomic, strong) BDPPkgFileReader reader;

@end

@implementation BDPURLProtocol

+ (void)initialize {
    if (self == [BDPURLProtocol class] && !sInfoCache) {
        [self resetInfoCache];
    }
}

+ (void)resetInfoCache {
    sInfoCache = [[NSCache alloc] init];
    sInfoCache.countLimit = 10;
    sLogExetensions = [NSSet setWithObjects:@"js", @"json", nil];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    BOOL isHandling = [[[self class] propertyForKey:BDP_REQUEST_KEY inRequest:request] boolValue];
    return !isHandling && ^{
        NSString *uniqueKey = [BDPAppLoadURLInfo uniqueKeyForURLRequest:request];
        BDPAppLoadURLInfo *info = [sInfoCache objectForKey:uniqueKey];
        if (!info) { // 有缓存
            info = [[BDPURLProtocolManager sharedManager] infoOfRequest:request];
            if (info) {
                [sInfoCache setObject:info forKey:uniqueKey];
            }
        }
        
        if(![BDPURLProtocolManager sharedManager].disableProtocolLog && info && info.folder == BDPAccessFolderJSSDK) {
            BDPLogInfo(@"[BDPURLProtocol] canInitWithRequest:%@", BDPSafeString(info.requestURL.absoluteString));
        }
        
        if (info && [request isKindOfClass:[NSMutableURLRequest class]]) {
            [[self class] setProperty:@YES forKey:BDP_REQUEST_KEY inRequest:(NSMutableURLRequest *)request];
        }
        return info != nil;
    }();
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    /*
     URLProtocol官方使用姿势
     https://developer.apple.com/library/archive/samplecode/CustomHTTPProtocol/Listings/Read_Me_About_CustomHTTPProtocol_txt.html
     */
    NSString *uniqueKey = [BDPAppLoadURLInfo uniqueKeyForURLRequest:self.request];
    BDPAppLoadURLInfo *info = [sInfoCache objectForKey:uniqueKey] ?: [[BDPURLProtocolManager sharedManager] infoOfRequest:self.request];
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:info.uniqueID];
    switch (info.folder) {
        case BDPAccessFolderTTPKG: {
            BDPLogDebug(@"[BDPURLProtocol] startLoading %@, %@, %@, %@, %@, %@", self.request.URL.absoluteString, self.request.allHTTPHeaderFields, info.appID, @(info.folder), info.pkgName, info.realPath)
            // 有begin才做埋点
            NSDate *begin = [sLogExetensions containsObject:info.realPath.pathExtension ?: @""] ? [NSDate date] : nil;
            
            BDPPkgFileReader reader;

            reader = [[BDPAppLoadManager shareService] tryGetReaderInMemoryWithUniqueID:info.uniqueID];
            
            if (!reader) {
                // 上面的逻辑稳定后，可以删除这段代码
                // TODO: 这里无法区分是来自 preview 还是 current 版本，根本原因是 preview 和 current 两个版本未做隔离，也无法区分是多个实例中的哪一个。关键是要解决：如何从这里拿到上下文信息？
                reader = [[BDPAppLoadManager shareService] tryGetReaderInMemoryWithAppID:info.appID pkgName:info.pkgName];
            }
            //如果是分包的情况，需要取包名对应的 reader 读取分包内数据
            if (common.isSubpackageEnable) {
                BDPPkgFileReader readerWithPackageName = [[BDPSubPackageManager sharedManager] getFileReaderWithPackageName:info.pkgName];
                if (readerWithPackageName!=nil && readerWithPackageName!=reader) {
                    reader = readerWithPackageName;
                }
            }
            if (!reader) {
                [self handleResponseData:nil ofURLInfo:info withError:OPErrorWithCode(GDMonitorCode.try_get_reader_failed)];
                break;
            }
            BDPUniqueID *uniqueId = reader.basic.uniqueID;
            WeakSelf;
            [reader readDataWithFilePath:info.realPath syncIfDownloaded:YES dispatchQueue:nil completion:^(NSError * _Nullable error, NSString * _Nonnull pkgName, NSData * _Nullable data) {
                StrongSelfIfNilReturn;
                [self handleResponseData:data ofURLInfo:info withError:error];
                if (begin) {
                    BDPMonitorLoadTimeline(@"get_file_content_from_ttpkg_end", @{ @"file_path": info.realPath ?: @""}, uniqueId);
                }
            }];
            if (begin) {
                BDPMonitorLoadTimelineDate(@"get_file_content_from_ttpkg_begin", @{ @"file_path": info.realPath ?: @""}, begin, uniqueId);
            }
        }
            break;
        case BDPAccessFolderJSSDK: {
            NSString *absFilePath = [[[BDPGetResolvedModule(BDPStorageModuleProtocol, BDPTypeNativeApp) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLib] stringByAppendingPathComponent:info.realPath ?: @""];
            NSError *error = nil;
            NSData *data = [NSData lss_dataWithContentsOfFile:absFilePath options:NSDataReadingMappedIfSafe error:&error];
            
            [self handleResponseData:data ofURLInfo:info withError:error];
            
            if(![BDPURLProtocolManager sharedManager].disableProtocolLog) {
                BDPLogInfo(@"[BDPURLProtocol] startLoading JSSDK, hasData:%@, filePath:%@",@(data != nil ? true : false), BDPSafeString(info.requestURL.absoluteString));
            }
        }
            break;
        case BDPAccessFolderSandBox: {
            NSString *absPath = info.realPath ?: @"";
            NSError *error = nil;
            NSData *data = [NSData lss_dataWithContentsOfFile:absPath options:NSDataReadingMappedIfSafe error:&error];
            [self handleResponseData:data ofURLInfo:info withError:error];
        }
            break;
        default:
            [self handleResponseData:nil ofURLInfo:nil withError:OPErrorWithMsg(GDMonitorCodeAppLoad.path_invalid, @"invalid file path")];
            break;
    }
}

- (void)handleResponseData:(NSData *)data ofURLInfo:(BDPAppLoadURLInfo *)info withError:(NSError *)error
{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
        BDPLogError(@"url protocol error, info=%@, error=%@", info.realPath, error);
        return;
    }
    // 解析
    NSString *mimeType = BDPMIMETypeOfFilePath(info.realPath);
    NSURLResponse *response = nil;
    if (info.folder == BDPAccessFolderSandBox && [info.requestURL.scheme isEqualToString:BDP_TTFILE_SCHEME]) {
        /// 沙箱文件收敛后，protocolPathToAbsPath 给前端返回 ttfile://user 或 ttfile://temp。
        /// 同时 Canvas 等前端渲染场景需要支持跨域（crossOrigin = 'anonymous'），当前 JSSDK 文件是加载在 file origin 下的，经过实测：
        /// 发出 ttfile request 的 origin = file, 返回 ttfile scheme，会有跨域问题。
        /// 发出 ttfile request 的 origin = file, 返回 file scheme, 会有跨域问题。
        /// 发出 ttfile request 的 origin = file, 返回 https scheme, 不会有跨域问题。
        NSURLComponents *cp = [NSURLComponents componentsWithString:self.request.URL.absoluteString];
        cp.scheme = @"https";
        response = [self makeCORSResponseWithURL:cp.URL mimeType:mimeType];
    } else if ((info.folder == BDPAccessFolderJSSDK && [info.requestURL.query isEqualToString:BDP_JSSDK_MASK]) || [mimeType hasPrefix:@"image"]) {
        response = [self makeCORSResponseWithURL:info.requestURL mimeType:mimeType];
    } else {
        NSURLComponents *cp = [NSURLComponents componentsWithString:self.request.URL.absoluteString];
        cp.scheme = @"https";
        response = [[NSURLResponse alloc] initWithURL:cp.URL
                                             MIMEType:mimeType
                                expectedContentLength:data.length
                                     textEncodingName:nil];
    }
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (NSHTTPURLResponse *)makeCORSResponseWithURL:(NSURL *)url mimeType: (NSString *)mimeType {
    return [[NSHTTPURLResponse alloc] initWithURL:url
                                       statusCode:200
                                      HTTPVersion:@"1.1"
                                     headerFields:@{
        @"Access-Control-Allow-Origin": @"*",
        @"Content-Type": [NSString stringWithFormat:@"%@; charset=utf-8", mimeType]
    }];
}

- (void)stopLoading
{
    
}

@end

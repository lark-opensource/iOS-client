//
//  BDDYCMain+Internal.m
//  BDDynamically
//
//  Created by zuopengliu on 7/1/2018.
//

#import "BDBDQuaterback+Internal.h"

#import <Brady/BDBrady.h>

#import "BDDYCMacros.h"
#import "BDDYCSessionTask.h"
#import "BDDYCModuleManager.h"
#import "BDDYCDownloader.h"
#import "BDDYCDevice.h"
#import "NSString+DYCExtension_Internal.h"
#import "BDBDModule.h"
#import "BDDYCURL.h"
#import "BDDYCErrCode.h"
#import "BDDYCEngineHeader.h"


#pragma mark -

@implementation BDBDQuaterback (Scheme)

+ (BOOL)handleOpenURL:(NSURL *)url
{
    if (!url || ![url isKindOfClass:[NSURL class]]) return NO;
    
    BDDYCURL *dycURL = [BDDYCURL DYCURLWithNSURL:url];
    if (![dycURL canHandle]) return NO;
    
    // TODO:
    if ([dycURL isStartScheme]) {
        [[self sharedMain] runBrady];
    } else if ([dycURL isCloseScheme]) {
        [[self sharedMain] closeBrady];
    } else if ([dycURL isFetchScheme]) {
        [self fetchServerData];
    } else {
        
    }
    
    return YES;
}

@end



#pragma mark -

@implementation BDBDQuaterback (DEBUG_HELP)

+ (void)loadFileAtPath:(NSString *)filePath
{
    NSString *fileExt = [filePath pathExtension];
    if (!fileExt || [fileExt length] == 0) {
        BDDYCAssert(NO && "Unsupported file format ...");
        return;
    }
    
    if ([BDDYCGetBitcodeEngineFormats() containsObject:fileExt]) {
        bdlli::Engine::loadModuleAtPath(filePath.UTF8String);
    } else {
        BDDYCAssert(NO && "Unsupported file format ...");
    }
}

+ (void)loadZipFileAtPath:(NSString *)filePath
{
    __weak BDBDQuaterback *weakSelf = [BDBDQuaterback sharedMain];
    NSString *armName = [BDDYCDevice getBCValidARCHString];
    if (![filePath.lastPathComponent bddyc_containsString:armName]) {
        BDDYCAssert(NO && "File name doesn't contain arm info, is wrong !!!");
    }
    [BDDYCDownloader unzipZipFile:filePath toDirecotry:KBDDYCQuaterbackMainDirectory completion:^(id aDYCModule, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error || !aDYCModule) {
//            if ([strongSelf.delegate respondsToSelector:@selector(moduleData:didFetchWithError:)]) {
//                [strongSelf.delegate moduleData:aDYCModule didFetchWithError:error];
//            }
            return;
        }
        
        [strongSelf loadDYCModule:aDYCModule errorBlock:^(NSError *error) {
            
        }];
    }];
}

@end



#pragma mark -

@implementation BDBDQuaterback (ModuleDataFetching)

+ (id<BDDYCSessionTask>)fetchModuleDataWithCompletion:(void (^)(NSArray *modules, NSError *error))completionHandler
{
    return [[self sharedMain] fetchModuleDataWithCompletion:completionHandler];
}

- (id<BDDYCSessionTask>)fetchModuleDataWithCompletion:(void (^)(NSArray *modules, NSError *error))completionHandler
{
    BDDYCModuleRequest *moduleRequest = [BDDYCModuleRequest new];
    moduleRequest.aid               = self.conf.aid;
    moduleRequest.deviceId          = self.conf.deviceId;
    moduleRequest.channel           = self.conf.channel;
    moduleRequest.appVersion        = self.conf.appVersion;
    moduleRequest.appBuildVersion   = self.conf.appBuildVersion;
    moduleRequest.domainName        = self.conf.domainName;
    moduleRequest.queryParams       = [self.conf commonParams];
    moduleRequest.engineType        = 0;
    moduleRequest.quaterbacks       = [[BDDYCModuleManager sharedManager] allToReportModules];
    moduleRequest.requestType       = (kBDDYCModuleRequestType)self.conf.requestType;
    
    __weak typeof(self) weakSelf = self;
    return [BDDYCDownloader fetchModulesWithRequest:moduleRequest toDirecotry:KBDDYCQuaterbackMainDirectory progress:^(BDBDModule *aDYCModule, NSInteger modelIdx, NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error || !aDYCModule) {
//            if (error && [strongSelf.delegate respondsToSelector:@selector(moduleData:didFetchWithError:)]) {
//                [strongSelf.delegate moduleData:aDYCModule didFetchWithError:error];
//            }
            return;
        }

        BOOL needLoad = YES;
        if (aDYCModule.config.loadEnable && aDYCModule.config.loadEnable.length > 0) {
            needLoad = [aDYCModule.config.loadEnable boolValue];
        }
        BDBDModule *oldDYCModule = [[BDDYCModuleManager sharedManager] moduleForName:aDYCModule.name];
        if (oldDYCModule != aDYCModule) {
            [[BDDYCModuleManager sharedManager] removeModule:oldDYCModule];
            [[BDDYCModuleManager sharedManager] addModule:aDYCModule];
        }

        if (/*![self isBradyRunning] &&*/ needLoad) {
            // hotload
            [strongSelf loadDYCModule:aDYCModule errorBlock:^(NSError *error) {

            }];
        } else {
            // Get old module

        }
    } completion:^(NSArray *modules, NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (modules.count == 0 && error) {
//            if ([strongSelf.delegate respondsToSelector:@selector(didFailFetchListWithError:)]) {
//                [strongSelf.delegate didFailFetchListWithError:error];
//            }
        }

        if (completionHandler != NULL) {
            completionHandler(modules, error);
        }
        
        // save new module list to local file
        [[BDDYCModuleManager sharedManager] saveToFile];
    }];
}

@end

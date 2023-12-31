//
//  BDDYCModule.m
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import "BDBDModule.h"

#import <BDAlogProtocol/BDAlogProtocol.h>
#import <Brady/BDBrady.h>

#import "BDDYCModule+Internal.h"
#import "BDDYCMacros.h"
#import "BDDYCSecurity.h"
#import "BDDYCModuleModel.h"
#import "BDDYCDevice.h"
#import "BDDYCErrCode.h"
#import "BDDYCModelKey.h"
#import "NSString+DYCExtension_Internal.h"
#import "BDDYCUtils.h"
#import "BDDYCModuleManager.h"
#import "BDDFileUtil.h"
#import "BDBDQuaterback.h"


NSString *const kBDDYCModuleConfigChannelList = @"channelList";
NSString *const kBDDYCModuleConfigAppVersionList = @"appVersionList";
NSString *const kBDDYCModuleConfigOsRange = @"osRange";
//NSString *const kBDDYCModuleConfigLoad = @"hotLoad";
NSString *const kBDDYCModuleConfigRedirectHookCls = @"redirectHookCls";
NSString *const kBDDYCModuleConfigLoadAlias = @"syncLoad";
NSString *const kBDDYCModuleConfigRedirectHookAlias = @"rac";
OBJC_EXTERN NSString *const kBDDYCModuleConfigEncrpt = @"se";
NSString *const kBDDYCModuleConfigHookType = @"hookType";
NSString *const kBDDYCModuleConfigEnableCallFuncLog = @"enableCallFnLog";
NSString *const kBDDYCModuleConfigEnableLoadintime = @"realtimeLoad";
NSString * const kBDDYCModuleLazyLoadFrameworks = @"lazyLoadFrameworks"; // 依赖的懒加载的动态库数组 ["framework1", "framework2"]
NSString * const kBDDYCModuleDynamicLoadSymbols = @"dynamicLoadSymbolInfo"; // 需要动态查找的符号及其动态库 {"symbol_name" : "framework_name"}

static NSString *const ModuleConfigKeyEnablePrintLog = @"enablePrintLog";
static NSString *const ModuleConfigKeyEnableModInitLog = @"enableModInitLog";
static NSString *const ModuleConfigKeyEnableInstExecLog = @"enableInstExecLog";
static NSString *const ModuleConfigKeyEnableInstCallFrameLog = @"enableInstCallFrameLog";
static NSString *const ModuleConfigKeySerializeNativeSymbolLookup = @"serializeNativeSymbolLookup";
static NSString *const ModuleConfigKeyBindSymbolMaxConcurrentOperationCount = @"bindSymbolMaxConcurrentOperationCount";

using namespace bdlli;

@implementation BDDYCModuleConfig

@end

#pragma mark -

@interface BDBDModule ()
@property (nonatomic, strong, readwrite) NSError *loadError;
@property (nonatomic, assign, readwrite) BOOL loaded;
@property (nonatomic, assign, readwrite) BOOL removed;
@property (nonatomic, strong, readwrite) NSArray *files;
@property (nonatomic,   copy, readwrite) NSString *bundlePath;
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, assign, readwrite) BOOL markAsEncrypted;

@property (nonatomic, strong) BDDYCModuleConfig *config;
@end

@implementation BDBDModule

#pragma mark -

BDDYC_DEBUG_DESCRIPTION

#pragma mark -

+ (instancetype)moduleWithFiles:(NSArray *)files
{
    return [[self alloc] initWithFiles:files create:NO];
}

+ (instancetype)moduleWithBundle:(id)bundleName
{
    return [[self alloc] initWithBundle:bundleName create:NO];
}

- (instancetype)initWithBundle:(id)bundleName create:(BOOL)created
{
    if ((self = [self init])) {
        _bundlePath = bundleName;
    }
    return self;
}

- (instancetype)initWithFiles:(NSArray *)files create:(BOOL)created
{
    if ((self = [self init])) {
        _files = [files copy];
        [self initConfigWithFiles:[files copy]];
    }
    return self;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _loaded  = NO;
        _removed = NO;
    }
    return self;
}

- (id)decryptedDataAtPath:(NSString *)path error:(NSError *__autoreleasing *)error
{
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    if ([self isMarkAsEncrypted]) {
        fileData = [BDDYCSecurity AESDecryptData:fileData
                                       keyString:self.moduleModel.privateKey
                                        ivString:nil];
    }
    NSString *fileString = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    return fileString;
}

- (BOOL)load
{
    return [self loadAndReturnError:NULL];
}

- (BOOL)loadAndReturnError:(NSError *__autoreleasing *)error {
    return [self loadAndReturnError:error skipsFileNameValidation:NO];
}

- (BOOL)loadAndReturnError:(NSError *__autoreleasing  _Nullable *)error
   skipsFileNameValidation:(BOOL)skipFileNameValidation {
 
//    if (_loaded) return YES;
    if (_files) {
        [_files enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL *stop) {
            // 忽略目录
            BOOL isDir = NO;
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir]) {
                [BDDYCModuleManager clearLocalQuaterbackWithModule:self];
                return;
            }
            if (isDir) return;
            
            NSInteger fileType = [BDDYCDevice moduleFileTypeForFile:filePath];
            if (fileType == BDDYCModuleFileTypeBitcode) {
                NSString *archName = [BDDYCDevice getBCValidARCHString];
                NSString *fileLastPathComponent = filePath.lastPathComponent;
                NSString *mapArcName = [[BDDYCDevice getiPhoneARCHSMap] objectForKey:archName]?:@"";
                BOOL fileNameValidated = skipFileNameValidation;
                fileNameValidated |= ([fileLastPathComponent bddyc_containsString:archName] ||
                                      [fileLastPathComponent bddyc_containsString:mapArcName]);
                if (fileNameValidated && [BDDYCUtils isValidPatchWithConfig:self.config
                                                            needStrictCheck:NO]) {
//                    BDALOG_PROTOCOL_INFO_TAG(@"better",@"will load betters archName: %@ lastPathComponent: %@ channel list : %@ version list : %@",archName,fileLastPathComponent,self.config.channelList,self.config.appVersionList);
                    auto MC = std::make_unique<ModuleConfiguration>();
                    MC->path = filePath.UTF8String;
                    MC->name = self.moduleModel.name.UTF8String;
                    MC->version = self.moduleModel.version.integerValue;
                    MC->async = self.moduleModel.isAsync;
                    MC->hookType = (KKBradyHookType)self.config.hookType;
                    MC->enableCallFuncLog = self.config.enableCallFuncLog;
                    MC->loadInTime = self.config.enableLoadIntime;
                    MC->logConfiguration.enablePrintLog = self.config.enablePrintLog;
                    MC->logConfiguration.enableModInitLog = self.config.enableModInitLog;
                    MC->logConfiguration.enableInstExecLog = self.config.enableInstExecLog;
                    MC->logConfiguration.enableInstCallFrameLog = self.config.enableInstCallFrameLog;
                    MC->serializeNativeSymbolLookup = self.config.serializeNativeSymbolLookup;
                    MC->bindSymbolMaxConcurrentOperationCount = self.config.bindSymbolMaxConcurrentOperationCount;
                    Engine::instance().loadModule(std::move(MC));
                    [[BDDYCModuleManager sharedManager] addLoadedModule:self.moduleModel];
                } else {
//                    BDDYCAssert(NO && "File name doesn't contain [ARM] info, is wrong !!!");
                    BDALOG_PROTOCOL_ERROR_TAG(@"better",@"did not load betters archName: %@ lastPathComponent: %@ channel list : %@ version list : %@",archName,fileLastPathComponent,self.config.channelList,self.config.appVersionList);
                }
            } else {
                BDALOG_PROTOCOL_ERROR_TAG(@"Unsupport file format: %@", filePath);
            }
        }];
    } else if (_bundlePath) {
        NSError *loadError;
        _loaded = [_bundle loadAndReturnError:&loadError];
        if (error) *error = [loadError copy];
        self.loadError = loadError;
    }
    return _loaded;
}

- (void)unload
{
    if (_files) {
        _loaded = NO;
    } else if (_bundlePath) {
        _loaded = [self.bundle unload];
    }
}

- (void)unloadAndRemove
{
    [self unload];
    [self remove];
}

- (void)remove
{
    if (_files) {
        _loaded = NO;
        [_files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:obj]) {
                    [[NSFileManager defaultManager] removeItemAtPath:obj error:NULL];
                }
            }
        }];
    } else if (_bundlePath) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:_bundlePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:_bundlePath error:NULL];
        }
    }
    _removed = YES;
}

#pragma mark -

- (void)initModuleModel {
    self.moduleModel = [BDDYCModuleModel new];
}

- (instancetype)initWithPropertyDictionary:(NSDictionary *)dict
{
    if (!dict || [dict count] == 0) return nil;
    
    NSArray  *relativePaths = dict[kBDDYCPatchFilePathsKey];
    NSString *bundlePath    = dict[kBDDYCPatchFilePathsKey];
    if (!relativePaths && !bundlePath) return nil;
    
    // Get absolute path
    // 将补丁相对路径拼接成绝对路径
    NSString *currLibDir = DYCGetCurrentLibraryDirectory();
    NSMutableArray *mutableFilePaths = [NSMutableArray new];
    [relativePaths enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSString *filePath = [currLibDir stringByAppendingPathComponent:obj];
        if (filePath) [mutableFilePaths addObject:filePath];
    }];
    
    if ((self = [super init])) {
        BDDYCModuleModel *aModuleModel = [BDDYCModuleModel modelWithDictionary:dict];
        self.moduleModel    = aModuleModel;
        self.files          = [mutableFilePaths copy];
        self.bundlePath     = bundlePath;

        [self initConfigWithFiles:[self.files copy]];
    }
    return self;
}

- (void)initConfigWithFiles:(NSArray *)files {
    [files enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL *stop) {
        // 忽略目录
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir]) {
            return;
        }
        if (isDir) return;

        NSInteger fileType = [BDDYCDevice moduleFileTypeForFile:filePath];
       if (fileType == BDDYCModuleFileTypePlist) {
//           NSDictionary *dataList = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
           NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:filePath];

           BDDYCModuleConfig *config = [[BDDYCModuleConfig alloc] init];
           BOOL encrypted = [[data objectForKey:kBDDYCModuleConfigEncrpt] boolValue];
           config.encrypted = encrypted;
           if (encrypted) {
               config.loadEnable = [[data objectForKey:kBDDYCModuleConfigLoadAlias] isKindOfClass:[NSString class]]?[data objectForKey:kBDDYCModuleConfigLoadAlias]:nil;
               config.racEnable = [[data objectForKey:kBDDYCModuleConfigRedirectHookAlias] boolValue];
           } else {
//               config.load = [[data objectForKey:kBDDYCModuleConfigLoad] isKindOfClass:[NSString class]]?[data objectForKey:kBDDYCModuleConfigLoad]:nil;
//               config.racEnable = [[data objectForKey:kBDDYCModuleConfigRedirectHookCls] isKindOfClass:[NSString class]]?[[data objectForKey:kBDDYCModuleConfigRedirectHookCls] boolValue]:NO;
           }
           config.appVersionList = [[data objectForKey:kBDDYCModuleConfigAppVersionList] isKindOfClass:[NSArray class]]?[data objectForKey:kBDDYCModuleConfigAppVersionList]:nil;
           config.channelList = [[data objectForKey:kBDDYCModuleConfigChannelList] isKindOfClass:[NSArray class]]?[data objectForKey:kBDDYCModuleConfigChannelList]:nil;
//           lazyLoadDlibList
           config.lazyLoadDlibList = [[data objectForKey:kBDDYCModuleLazyLoadFrameworks] isKindOfClass:[NSArray class]]?[data objectForKey:kBDDYCModuleLazyLoadFrameworks]:nil;
           config.osVersionRange = [[data objectForKey:kBDDYCModuleConfigOsRange] isKindOfClass:[NSDictionary class]]?[data objectForKey:kBDDYCModuleConfigOsRange]:nil;
//           exportSymbols
           config.exportSymbols = [[data objectForKey:kBDDYCModuleDynamicLoadSymbols] isKindOfClass:[NSDictionary class]]?[data objectForKey:kBDDYCModuleDynamicLoadSymbols]:nil;
           int hooktype = [[data objectForKey:kBDDYCModuleConfigHookType] isKindOfClass:[NSString class]]?[[data objectForKey:kBDDYCModuleConfigHookType] intValue]:0;
           if ([UIDevice currentDevice].systemVersion.floatValue >= 14.199 && hooktype == 0) {
               hooktype = 2;
           }
           config.hookType = hooktype;
           config.enableCallFuncLog = [[data objectForKey:kBDDYCModuleConfigEnableCallFuncLog] boolValue];
           config.enableLoadIntime = [[data objectForKey:kBDDYCModuleConfigEnableLoadintime] boolValue];
           config.enablePrintLog = [data[ModuleConfigKeyEnablePrintLog] boolValue];
           config.enableModInitLog = [data[ModuleConfigKeyEnableModInitLog] boolValue];
           config.enableInstExecLog = [data[ModuleConfigKeyEnableInstExecLog] boolValue];
           config.enableInstCallFrameLog = [data[ModuleConfigKeyEnableInstCallFrameLog] boolValue];
           config.serializeNativeSymbolLookup = [data[ModuleConfigKeySerializeNativeSymbolLookup] boolValue];
           config.bindSymbolMaxConcurrentOperationCount = [data[ModuleConfigKeyBindSymbolMaxConcurrentOperationCount] integerValue];

           self.config = config;
        }
    }];
}

#pragma mark -

- (NSDictionary *)toPropertyListDictionary
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict addEntriesFromDictionary:[self.moduleModel toPropertyListDictionary]];
    
    // 仅仅保存补丁文件相对路径
    NSMutableArray *relativePaths = [NSMutableArray new];
    NSString *currLibDir __unused = DYCGetCurrentLibraryDirectory();
    [self.files enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeOfString:BDDYC_MODULE_ROOT_DIR];
        NSString *relativePath = (range.location != NSNotFound ? [obj substringFromIndex:range.location] : nil);
        if (!relativePath) {
            NSArray *comps = [obj componentsSeparatedByString:BDDYC_MODULE_ROOT_DIR];
            relativePath = [NSString stringWithFormat:@"%@%@", BDDYC_MODULE_ROOT_DIR, [comps lastObject]];
        }
        if (relativePath) [relativePaths addObject:relativePath];
    }];
    [mutableDict setValue:relativePaths
                   forKey:kBDDYCPatchFilePathsKey];
    [mutableDict setValue:self.bundlePath
                   forKey:kBDDYCPatchBundlePathKey];
    
    return [mutableDict copy];
}

- (NSDictionary *)toReportDicitonary
{
    return [_moduleModel toReportDicitonary];
}

- (NSDictionary *)toLogDicitonary {
    return [_moduleModel toLogDicitonary];
}

#pragma mark -

- (id)operatingStatus
{
    return nil;
}

#pragma mark - Setter/Getter

- (BOOL)isMarkAsEncrypted
{
    return [self.moduleModel.privateKey length] > 0;
}

- (NSBundle *)bundle
{
    if (!_bundle) return _bundle;
    if (_bundlePath) {
        _bundle = [NSBundle bundleWithPath:_bundlePath];
    }
    return _bundle;
}

- (NSString *)name
{
    return _moduleModel.name;
}

@end



#pragma mark -

@implementation BDDYCModuleOperatingStatus

@end


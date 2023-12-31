//
//  TSPKAspectManager.m
//  Indexer
//
//  Created by bytedance on 2022/3/31.
//

#import "TSPKAspectManager.h"
#import "TSPKStoreManager.h"
#import "TSPKEntryManager.h"
#import "TSPKDetectManager.h"
#import "TSPKDetectPlanModel.h"

#import <dlfcn.h>
#import <mach-o/loader.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TSPrivacyKit/TSPKAspector.h>
#import <TSPrivacyKit/TSPKAspectModel.h>
#import <TSPrivacyKit/TSPKConfigs.h>
#import <TSPrivacyKit/TSPKLogger.h>
#import <TSPrivacyKit/TSPKMonitor.h>
#import <TSPrivacyKit/TSPKReporter.h>
#import <TSPrivacyKit/TSPKUploadEvent.h>
#import <TSPrivacyKit/TSPKUtils.h>
#import <TSPrivacyKit/TSPKDetectPipeline.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "TSPKBacktraceStore.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import "TSPKHostEnvProtocol.h"
#import <TSPrivacyKit/TSPKSignalManager+public.h>

static NSString *TSPKAspectActionSaveBacktrace = @"saveBacktrace";
static NSString *TSPKAspectActionSignal = @"signal";

@interface TSPKAspectManager ()

+ (void)executeActionsWithModel:(TSPKAspectModel *)model;

@end

static NSMutableDictionary<NSString *, NSMutableDictionary *> *aspectMap;

TSPKAspectModel *PnSGetAspectModel(NSString *klassName, NSString *methodName)
{
    if (!klassName || !methodName) {
        return nil;
    }
    NSDictionary *methodMap = [aspectMap btd_dictionaryValueForKey:klassName];
    return [methodMap btd_objectForKey:methodName default:nil];
}

static Class PnSGetClass(id arg)
{
    Class klass = nil;
    if (class_isMetaClass(object_getClass(arg))) {
        klass = arg;
    } else {
        klass = [arg class];
    }
    return klass;
}

static id PnSInvocationFuse_obj(id, SEL);
id PnSInvocationFuse_obj(id arg1, SEL cmd)
{
    Class klass = PnSGetClass(arg1);
    NSString *cmdName = NSStringFromSelector(cmd);
    TSPKAspectModel *model = PnSGetAspectModel(NSStringFromClass(klass), cmdName);
    return [TSPKUtils createDefaultInstance:model.returnType defalutValue:model.returnValue];
}

static void *PnSInvocationFuse_struct(void *, id, SEL);
void *PnSInvocationFuse_struct(void *ret, id arg1, SEL cmd)
{
//    Class klass = PnSGetClass(arg1);
//    NSString *klassName = NSStringFromClass(klass);
//    NSString *cmdName = NSStringFromSelector(cmd);
//    TSPKAspectMethodModel *model = [[TSPKDowngrader sharedDowngrader]aspectModelWith:klassName with:cmdName];
    CGRect *r = (CGRect *)ret;
    *r = CGRectMake(0, 0, 0, 0);
    return 0;
}

static long long PnSInvocationFuse_val(id, SEL);
long long PnSInvocationFuse_val(id arg1, SEL cmd)
{
    Class klass = PnSGetClass(arg1);
    NSString *klassName = NSStringFromClass(klass);
    NSString *cmdName = NSStringFromSelector(cmd);
    TSPKAspectModel *model = PnSGetAspectModel(klassName, cmdName);
    return [TSPKUtils createDefaultValue:model.returnType defalutValue:model.returnValue];
}

static long PnSInvocationFuseDummy(id, SEL);
long PnSInvocationFuseDummy(id arg1, SEL cmd)
{
    return 0;
}

static IMP onApiEntry(id arg1, SEL cmd, SEL oriCmd, IMP oriImp, void *retAddress);
static IMP onApiEntry(id arg1, SEL cmd, SEL oriCmd, IMP oriImp, void *retAddress)
{
    IMP retImp = oriImp;
    Class klass = PnSGetClass(arg1);
    NSString *klassName = NSStringFromClass(klass);
    NSString *cmdName = NSStringFromSelector(oriCmd);
    
    BOOL isClassMethod = class_isMetaClass(object_getClass(arg1));
    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"aspect-test onApiEntry %@ %@ method:%@ is called", klassName, isClassMethod ? @"class" : @"instance", cmdName]];
    
    TSPKAspectModel *model = PnSGetAspectModel(klassName, cmdName);
    
    // actions execute
    [TSPKAspectManager executeActionsWithModel:model];
    
    if (model.needLogCaller) {
        NSString *backtrace = @"PnS Caller Info: ";
        Dl_info info;
        memset(&info, 0, sizeof(info));
        if (dladdr(retAddress, &info) != 0) {
            backtrace = [backtrace stringByAppendingString:[NSString stringWithFormat:@"caller address:%p - dli_fname=%@ - dli_sname=%@ - base address:%p - symbol address:%p, when called %@-%@", retAddress, [NSString stringWithUTF8String:info.dli_fname?:""], [NSString stringWithUTF8String:info.dli_sname?:""], info.dli_fbase, info.dli_saddr, arg1, cmdName]];
        }
        backtrace = [backtrace stringByAppendingString:[NSThread  callStackSymbols].description];
        [TSPKLogger logWithTag:@"PrivacyCheckInfo" message:backtrace];

//        void *addr[2];
//        int nframes = backtrace(addr, sizeof(addr)/sizeof(*addr));
//        if (nframes > 1) {
//            char **syms = backtrace_symbols(addr, nframes);
//            NSLog(@"%s: caller: %s", __func__, syms[1]);
//            free(syms);
//        } else {
//            NSLog(@"%s: *** Failed to generate backtrace.", __func__);
//        }
    }

    BOOL needFuse = NO;
    if (model && model.aspectPosition == TSPKAspectPositionPre) {
        TSPKHandleResult *ret = [TSPKDetectPipeline handleAPIAccess:arg1 AspectInfo:model];// handleAPIAccess returns if it needs downgrade
        needFuse = needFuse || ret.action == TSPKResultActionFuse;
    }
    if (needFuse) {
        if (model.returnTypeKind == TSPKAspectMethodReturnObject) {
            retImp = (IMP)PnSInvocationFuse_obj;
        } else if (model.returnTypeKind == TSPKAspectMethodReturnNone) {
            retImp = (IMP)PnSInvocationFuseDummy;
        } else if (model.returnTypeKind == TSPKAspectMethodReturnStruct) {
            retImp = (IMP)PnSInvocationFuse_struct;
        } else {
            retImp = (IMP)PnSInvocationFuse_val;
        }
    }

    return retImp;
}

static void onApiExit(id arg1, SEL cmd, SEL oriCmd);
static void onApiExit(id arg1, SEL cmd, SEL oriCmd)
{
    Class klass = PnSGetClass(arg1);
    NSString *klassName = NSStringFromClass(klass);
    NSString *cmdName = NSStringFromSelector(oriCmd);
//    NSLog(@"onMyExit %@-%@", arg1, cmdName);

    TSPKAspectModel *model = PnSGetAspectModel(klassName, cmdName);
    if (model && model.aspectPosition == TSPKAspectPositionPost) {
        [TSPKDetectPipeline handleAPIAccess:arg1 AspectInfo:model];
    }
}

@implementation TSPKAspectManager

+ (void)setupDynamicAspect
{
    [TSPKAspector setOnEntry:(IMP)onApiEntry];
    [TSPKAspector setOnExit:(IMP)onApiExit];

    if (!aspectMap) {
        aspectMap = [NSMutableDictionary new];
    }
    NSArray *aspects = [[TSPKConfigs sharedConfig]dynamicAspectConfigs];

    for (NSDictionary *obj in aspects) {
        TSPKAspectModel *aspectInfo = [[TSPKAspectModel alloc] initWithDictionary:obj];
        if (![self checkIfAllowKlass:aspectInfo.klassName]) {
            continue;
        }
        
        if (aspectInfo.aspectAllMethods) {
            if ([self isAspectClassAllMethodsEnabled]) {
                [self setupAspectClassAllMethodsWithInfo:aspectInfo dic:obj];
            }
        } else {
            [self setupAspectMethodWithInfo:aspectInfo];
        }
    }
}

+ (void)setupAspectMethodWithInfo:(TSPKAspectModel *)aspectInfo {
    if (!aspectInfo.klassName || !aspectInfo.methodName) {
        return;
    }
    
    // determine method type
    if (aspectInfo.methodType == TSPKAspectMethodTypeUnknown) {
        Class klass = NSClassFromString(aspectInfo.klassName);
        SEL selector = NSSelectorFromString(aspectInfo.methodName);
        if (class_respondsToSelector(klass, selector)) {
            aspectInfo.methodType = TSPKAspectMethodTypeInstance;
        } else {
            Class metaKlass = object_getClass(klass);
            if (class_respondsToSelector(metaKlass, selector)) {
                aspectInfo.methodType = TSPKAspectMethodTypeClass;
            }
        }
    }
    // still not find, return
    if (aspectInfo.methodType == TSPKAspectMethodTypeUnknown) {
        return;
    }
    
    NSMutableDictionary *methodKeyedMap = aspectMap[aspectInfo.klassName];
    
    if (!methodKeyedMap) {
        methodKeyedMap = [NSMutableDictionary new];
        aspectMap[aspectInfo.klassName] = methodKeyedMap;
    }
    methodKeyedMap[aspectInfo.methodName] = aspectInfo;

    [aspectInfo fillPipelineType];
    
    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"%@ %@ %@ method:%@", aspectInfo.dataType, aspectInfo.klassName, aspectInfo.methodType == TSPKAspectMethodTypeClass ? @"class" : @"instance", aspectInfo.methodName]];

    [self executeAspectWithInfo:aspectInfo];
}

+ (void)setupAspectClassAllMethodsWithInfo:(TSPKAspectModel *)aspectInfo dic:(NSDictionary *)dic {
    NSString *klassName = aspectInfo.klassName;
    
    if (!klassName) {
        return;
    }
    // if class dic already exists, return
    if (aspectMap[klassName]) {
        return;
    }
    
    NSMutableDictionary *methodKeyedMap = [NSMutableDictionary new];
    aspectMap[klassName] = methodKeyedMap;
    
    // get instance methods
    Class clz = NSClassFromString(klassName);
    NSArray *instanceMethods = [self getAspectModelsForClass:clz];
    if (![instanceMethods containsObject:@"init"]) {
        instanceMethods = [instanceMethods arrayByAddingObject:@"init"];
    }
    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"%@ %@ instance methods:%@", aspectInfo.dataType, klassName, instanceMethods]];
    
    // get class methods
    Class metaClz = object_getClass(clz);
    NSArray *classMethods = [self getAspectModelsForClass:metaClz];
    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"%@ %@ class methods:%@", aspectInfo.dataType, klassName, classMethods]];
    
    // merge methods
    NSArray *methods = [classMethods arrayByAddingObjectsFromArray:instanceMethods];
    
    // handle & aspect
    [methods enumerateObjectsUsingBlock:^(NSString *  _Nonnull methodName, NSUInteger idx, BOOL * _Nonnull stop) {
        if (aspectInfo.ignoreInternalMethods && [methodName hasPrefix:@"_"]) {
            return;
        }
        
        TSPKAspectModel *aspectInfo = [[TSPKAspectModel alloc] initWithDictionary:dic];
        aspectInfo.methodName = methodName;
        if (idx < classMethods.count) {
            aspectInfo.methodType = TSPKAspectMethodTypeClass;
        } else {
            aspectInfo.methodType = TSPKAspectMethodTypeInstance;
        }
        [aspectInfo fillPipelineType];

        methodKeyedMap[aspectInfo.methodName] = aspectInfo;
        [self executeAspectWithInfo:aspectInfo];
    }];
}


+ (NSArray *)getAspectModelsForClass:(Class)clz {
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(clz, &methodCount); // any instance methods implemented by superclasses are not included

    NSMutableArray *mutableMethods = [NSMutableArray array];
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];

        const char* selName = sel_getName(method_getName(method));

        NSString *sel = [NSString stringWithCString:selName encoding:NSUTF8StringEncoding];
        
        NSArray *blockList = @[@"initialize", @"load", @"dealloc"];
        
        if (![sel hasPrefix:@"."] && ![sel hasPrefix:@"tspk"] && ![blockList containsObject:sel]) {
            [mutableMethods addObject:sel];
        }
    }

    free(methods);

    return mutableMethods.copy;
}

+ (void)executeAspectWithInfo:(TSPKAspectModel *_Nullable)aspectInfo
{
    TSPKStoreType storeType = (TSPKStoreType)aspectInfo.storeType;
    if (storeType != TSPKStoreTypeNone) {
        [[TSPKStoreManager sharedManager] initStoreOfStoreId:aspectInfo.pipelineType storeType:storeType];
    }
    
    TSPKEntryUnitModel *model = [TSPKEntryUnitModel new];
    model.entryIdentifier = aspectInfo.pipelineType;
    model.initAction = ^{
        TSPKAspectMethodType type = aspectInfo.methodType;
        switch (type) {
            case TSPKAspectMethodTypeUnknown:
                break;
            case TSPKAspectMethodTypeInstance:
                [TSPKAspector swizzleInstanceMethod:NSClassFromString(aspectInfo.klassName) Method:NSSelectorFromString(aspectInfo.methodName) ReturnStruct:(aspectInfo.returnTypeKind == TSPKAspectMethodReturnStruct)];
                break;
            case TSPKAspectMethodTypeClass:
                [TSPKAspector swizzleClassMethod:NSClassFromString(aspectInfo.klassName) Method:NSSelectorFromString(aspectInfo.methodName) ReturnStruct:(aspectInfo.returnTypeKind == TSPKAspectMethodReturnStruct)];
                break;
        }
    };
    model.storeType = storeType;
    [[TSPKEntryManager sharedManager] registerEntryType:aspectInfo.registerEntryType entryModel:model];
    [[TSPKEntryManager sharedManager] setEntryType:aspectInfo.registerEntryType enable:aspectInfo.enableDetector];

    NSArray<TSPKDetectPlanModel *> *allPlans = [TSPKDetectManager createPlanModelsWithAspectInfo:aspectInfo];
    for (TSPKDetectPlanModel *plan in allPlans) {
        [[TSPKDetectManager sharedManager] registerDetectPlan:plan];
    }
}

#pragma mark - allow

+ (BOOL)isAspectClassAllMethodsEnabled {
    return NO;
}

+ (BOOL)checkIfAllowKlass:(NSString *)klassName {
    return [self.allowKlassList containsObject:klassName] || [[self allowExternalKlassList] containsObject:klassName];
}

+ (NSArray *)allowExternalKlassList {
    id<TSPKHostEnvProtocol> hostEnv = PNS_GET_INSTANCE(TSPKHostEnvProtocol);
    if ([hostEnv respondsToSelector:@selector(externalAspectAllowKlassList)]) {
        return [hostEnv externalAspectAllowKlassList];
    } else {
        return nil;
    }
}

// for class compare
+ (NSArray *)allowKlassList
{
    NSArray *encodeList = @[
        @"QVZBdWRpb1JlY29yZGVy", // AVAudioRecorder
        @"QVZBdWRpb1Nlc3Npb24=", // AVAudioSession
        @"QVZDYXB0dXJlRGV2aWNl", // AVCaptureDevice
        @"Q0xMb2NhdGlvbk1hbmFnZXI=", // CLLocationManager
        @"TVBNZWRpYUxpYnJhcnk=", // MPMediaLibrary
        @"TVBNZWRpYVF1ZXJ5", // MPMediaQuery
        @"UEhQaG90b0xpYnJhcnk=", // PHPhotoLibrary
        @"UEhDb2xsZWN0aW9uTGlzdA==", // PHCollectionList
        @"UEhBc3NldENvbGxlY3Rpb24=", // PHAssetCollection
        @"UEhBc3NldENoYW5nZVJlcXVlc3Q=", // PHAssetChangeRequest
        @"UEhBc3NldA==", // PHAsset
        @"QVZDYXB0dXJlU2Vzc2lvbg==", // AVCaptureSession
        @"QVNJZGVudGlmaWVyTWFuYWdlcg==", // ASIdentifierManager
        @"QVRUcmFja2luZ01hbmFnZXI=", // ATTrackingManager
        @"VUlEZXZpY2U=", // UIDevice
        @"RUtFdmVudFN0b3Jl", // EKEventStore
        @"Q05Db250YWN0U3RvcmU=", // CNContactStore
        @"Q05EYXRhTWFwcGVyQ29udGFjdFN0b3Jl" // CNDataMapperContactStore
    ];

    NSMutableArray *decodeList = [NSMutableArray arrayWithCapacity:encodeList.count];
    [encodeList enumerateObjectsUsingBlock:^(NSString *_Nonnull encodeClass, NSUInteger idx, BOOL *_Nonnull stop) {
        [decodeList addObject:[TSPKUtils decodeBase64String:encodeClass]];
    }];

    return decodeList.copy;
}

#pragma mark - extra action

+ (void)executeActionsWithModel:(TSPKAspectModel *)model {
    NSArray <NSString *> *actions = model.actions;
    if (actions.count == 0) {
        return;
    }
    
    NSString *prefix = @"PNS_";
    
    for (NSString *action in actions) {
        if ([action isEqualToString:TSPKAspectActionSaveBacktrace]) {
            if (model.pipelineType.length > 0 && [model.pipelineType hasPrefix:prefix]) {
                NSString *pipelineType = [model.pipelineType stringByReplacingOccurrencesOfString:prefix withString:@""];
                [[TSPKBacktraceStore shared] saveCustomCallBacktraceWithPipelineType:pipelineType];
            }
        } else if ([action isEqualToString:TSPKAspectActionSignal]) {
            NSString *dataType = [model.dataType stringByReplacingOccurrencesOfString:prefix withString:@""];
            NSString *content = [NSString stringWithFormat:@"aspect %@_%@ is called", model.klassName, model.methodName];
            [TSPKSignalManager addSignalWithType:TSPKSignalTypeCustom permissionType:dataType content:content];
        }
    }
}

@end

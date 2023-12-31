//
//  ACCMomentATIMManager.m
//  Pods
//
//  Created by Pinka on 2020/6/8.
//

#import "ACCMomentATIMManager.h"
#import "ACCMomentMediaDataProvider.h"
#import "ACCMomentBIMResult+VEAIMomentMaterialInfo.h"
#import "ACCMomentMaterialSegInfo+VEAIMomentMaterialSegInfo.h"
#import "ACCMomentReframe+VEAIMomentReframeFrame.h"
#import "ACCFileDownloader.h"
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreationKitInfra/ACCBaseApiModel.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import "ACCMomentBIMResult+WCTTableCoding.h"
#import "ACCMomentDatabaseUpgradeManager.h"
#import <CreationKitInfra/NSString+ACCAdditions.h>

#import <BDWCDB/WCDB/WCDB.h>
#import <FileMD5Hash/FileHash.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectSDK_iOS/RequirementDefine.h>
#import <TTVideoEditor/VEAlgorithmInput.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/NSString+CameraClientResource.h>


static NSInteger const ACCMomentATIMManagerNewerTIMVersionCode = 2;

static float const ReFrameScoreDefault = 0.8;

static NSString *const ACCMomentATIMManagerMagicURL = @"effect";

NSString* ACCMomentATIMManagerPath(void)
{
    NSString *cachesDir = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"ACCMomentATIMManager"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachesDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachesDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return cachesDir;
}

NSString* ACCMomentATIMManagerAIMConfigPath(NSString *pannelName)
{
    return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", pannelName]];
}

static NSString* ACCMomentATIMManagerTIMModelPath(NSString *name)
{
    if (name.length) {
        return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:name];
    } else {
        return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:@"tempRec.model"];
    }
}

static NSString* ACCMomentATIMManagerTIMModelTmpPath(void)
{
    return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:@"tempRec.model.tmp"];
}

static NSString* ACCMomentATIMManagerTIMModelVersionPath(void)
{
    return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:@"tempRec.ver"];
}

static NSString* ACCMomentATIMManagerTIMModelNamePath(void)
{
    return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:@"tempRec.name"];
}

static NSString* ACCMomentATIMManagerTIMModelMd5Path(void)
{
    return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:@"tempRec.md5"];
}

static NSString* ACCMomentATIMManagerAIMURLPrefixPath(void)
{
    return [ACCMomentATIMManagerPath() stringByAppendingPathComponent:@"aimURLPrefix.plist"];
}

@interface ACCMomentTIMModelResp : ACCBaseApiModel

@property (nonatomic, copy) NSString *versionCode;

@property (nonatomic, copy) NSString *modelUrl;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *md5;

@end

@implementation ACCMomentTIMModelResp

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *jsonKeys = [[NSMutableDictionary alloc] initWithDictionary:[super JSONKeyPathsByPropertyKey]];
    
    jsonKeys[@"versionCode"] = @"version_code";
    jsonKeys[@"modelUrl"] = @"model_url";
    jsonKeys[@"name"] = @"name";
    jsonKeys[@"md5"] = @"md5";
    
    return jsonKeys;;
}

@end

@interface ACCMomentATIMManager ()

@property (nonatomic, strong) VEAIMomentAlgorithm *aiAlgorithm;

@property (nonatomic, strong) ACCMomentMediaDataProvider *dataProvider;

#pragma mark -
@property (nonatomic, assign, readwrite) BOOL aimIsReady;

@property (nonatomic, assign, readwrite) BOOL timIsReady;

@property (nonatomic, assign) BOOL timUseEffectPlatform;

@property (nonatomic, strong) NSMutableArray<ACCMomentATIMManagerAIMCompletion> *prepareAIMCompletions;

@property (nonatomic, copy  ) NSArray<VEAIMomentTemplatePair *> *templatePairs;

@property (nonatomic, strong) ACCMomentAIMomentModel *templateReferMoment;

@property (nonatomic, copy  ) ACCMomentATIMManagerTIMCompletion timCompletion;

@property (nonatomic, strong) dispatch_queue_t atimQueue;

@property (nonatomic, copy, readwrite) NSArray<NSString *> *urlPrefix;

@end

@implementation ACCMomentATIMManager

@synthesize aimIsReady = _aimIsReady, timIsReady = _timIsReady;

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static ACCMomentATIMManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[ACCMomentATIMManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _dataProvider = [ACCMomentMediaDataProvider normalProvider];
        _configJson = [[NSString alloc] initWithContentsOfFile:ACCMomentATIMManagerAIMConfigPath(@"moments") encoding:NSUTF8StringEncoding error:nil];
        _urlPrefix = [[NSArray alloc] initWithContentsOfFile:ACCMomentATIMManagerAIMURLPrefixPath()];
        _atimQueue = dispatch_queue_create("com.acc.at.manager", DISPATCH_QUEUE_SERIAL);
        _pannelName = @"moments";
        
        _prepareAIMCompletions = [[NSMutableArray alloc] init];
        
        // Check versionCode, If it is less than v2.0, skip the TIM Model
        NSString *timVersion = [[NSString alloc] initWithContentsOfFile:ACCMomentATIMManagerTIMModelVersionPath() encoding:NSUTF8StringEncoding error:nil];
        if (timVersion.length > 1 &&
            [timVersion substringWithRange:NSMakeRange(1, 1)].integerValue >= ACCMomentATIMManagerNewerTIMVersionCode) {
            NSString *tempRecName = [[NSString alloc] initWithContentsOfFile:ACCMomentATIMManagerTIMModelNamePath() encoding:NSUTF8StringEncoding error:nil];
            if (tempRecName.length) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:ACCMomentATIMManagerTIMModelPath(tempRecName)]) {
                    _timIsReady = YES;
                }
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpgraded:) name:kACCMomentDatabaseDidUpgradedNotification object:nil];
    }
    
    return self;
}

- (void)didUpgraded:(NSNotification *)noti
{
    _dataProvider = [ACCMomentMediaDataProvider normalProvider];
}

- (void)updateAIMConfig
{
    @weakify(self);
    NSString *pannelName = [self.pannelName copy];
    [EffectPlatform
     downloadEffectListWithPanel:pannelName
     completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
        @strongify(self);
        if (error) {
            AWELogToolError(AWELogToolTagEffectPlatform, @"[downloadEffectListWithPanel moment] -- error:%@", error);
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *arr = [[NSMutableArray alloc] init];
            [response.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *tmp = [obj.sdkExtra acc_jsonValueDecoded];
                if (tmp) {
                    NSMutableDictionary *oneConfig = [[NSMutableDictionary alloc] initWithDictionary:tmp];
                    if (obj.extra) {
                        oneConfig[@"extra"] = obj.extra;
                    }
                    if (obj.effectIdentifier) {
                        oneConfig[@"effectID"] = obj.effectIdentifier;
                    }
                    [arr addObject:oneConfig];
                }
            }];
            NSString *jsonStr = [arr acc_JSONString];
            if (arr.count == 0 ) {
                return;
            }
            
            if (jsonStr.length) {
                dispatch_async(self.atimQueue, ^{
                    [jsonStr acc_writeToFile:ACCMomentATIMManagerAIMConfigPath(pannelName) atomically:YES encoding:NSUTF8StringEncoding error:nil];
                    self.configJson = jsonStr;
                    self.urlPrefix = response.urlPrefix;
                    self->_aiAlgorithm = nil;
                });
            }
        });
    }];
}

- (void)updateTIMModel
{
    @weakify(self);
    [ACCNetService()
     requestWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.requestType = ACCRequestTypeGET;
        requestModel.urlString = [NSString stringWithFormat:@"%@/aweme/v1/moment/model/detail/", [ACCNetService() defaultDomain]];
        requestModel.objectClass = ACCMomentTIMModelResp.class;
    }
     completion:^(ACCMomentTIMModelResp * _Nullable resp, NSError * _Nullable error) {
        @strongify(self);
        if ([resp.modelUrl isEqualToString:ACCMomentATIMManagerMagicURL]) {
            self.timUseEffectPlatform = YES;
            self.timIsReady = [EffectPlatform isRequirementsDownloaded:@[@REQUIREMENT_MOMENT_TAG]];
        } else if (resp.modelUrl.length &&
                   resp.name.length &&
                   resp.versionCode.length &&
                   resp.md5.length &&
                   !error) {
            NSString *lastName = [[NSString alloc] initWithContentsOfFile:ACCMomentATIMManagerTIMModelNamePath() encoding:NSUTF8StringEncoding error:nil];
            NSString *lastMd5 = [[NSString alloc] initWithContentsOfFile:ACCMomentATIMManagerTIMModelMd5Path() encoding:NSUTF8StringEncoding error:nil];
            
            if (![lastMd5 isEqualToString:resp.md5]) {
                CFAbsoluteTime ctime = CFAbsoluteTimeGetCurrent();
                [[ACCFileDownloader sharedInstance]
                 downloadFileWithURLs:@[resp.modelUrl]
                 downloadPath:ACCMomentATIMManagerTIMModelTmpPath()
                 downloadProgress:nil
                 completion:^(NSError *error, NSString *filePath, NSDictionary *extraInfoDict) {
                    CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
                    [ACCMonitor() trackService:@"moment_tim_download"
                                        status:(!error && [[NSFileManager defaultManager] fileExistsAtPath:filePath])? 0: 1
                                         extra:@{
                                             @"duration": @(gap),
                                             @"version": resp.versionCode? : @""
                                         }];
                    
                    dispatch_async(self.atimQueue, ^{
                        @strongify(self);
                        if (!self) {
                            return;
                        }
                        
                        if (!error) {
                            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                                NSString *fileMd5 = [FileHash md5HashOfFileAtPath:filePath];
                                if ([fileMd5 isEqualToString:resp.md5] &&
                                    resp.versionCode.length > 1 &&
                                    [resp.versionCode substringWithRange:NSMakeRange(1, 1)].integerValue >= ACCMomentATIMManagerNewerTIMVersionCode) {
                                    self->_aiAlgorithm = nil;
                                    
                                    BOOL okFlag = YES;
                                    NSError *fileError;
                                    if (lastName.length) {
                                        okFlag = [[NSFileManager defaultManager] removeItemAtPath:ACCMomentATIMManagerTIMModelPath(lastName) error:&fileError];
                                    }
                                    
                                    if (okFlag &&
                                        [[NSFileManager defaultManager] moveItemAtPath:filePath
                                        toPath:ACCMomentATIMManagerTIMModelPath(resp.name)
                                         error:nil]) {
                                             [resp.versionCode acc_writeToFile:ACCMomentATIMManagerTIMModelVersionPath() atomically:YES encoding:NSUTF8StringEncoding error:nil];
                                             [resp.name acc_writeToFile:ACCMomentATIMManagerTIMModelNamePath() atomically:YES encoding:NSUTF8StringEncoding error:nil];
                                             [resp.md5 acc_writeToFile:ACCMomentATIMManagerTIMModelMd5Path() atomically:YES encoding:NSUTF8StringEncoding error:nil];
                                             self.timIsReady = YES;
                                    }
                                }
                            }
                        }
                    });
                }];
            }
        }
    }];
}

- (void)requestAIMResult:(ACCMomentATIMManagerAIMCompletion)completion
{
    if (!completion) {
        return;
    }
    
    if (!self.aimIsReady) {
        [self.prepareAIMCompletions addObject:completion];
        return;
    }
    
    [self realRequestAIMResultWithCompletions:@[completion]];
}

- (void)realRequestAIMResultWithCompletions:(NSArray<ACCMomentATIMManagerAIMCompletion> *)completions
{
    [self.dataProvider loadBIMResultToSelectObj:^(WCTSelect * _Nonnull select, NSError * _Nullable error) {
        dispatch_async(self.atimQueue, ^{
            ACCMomentBIMResult *oneBim = nil;
            NSMutableArray *input = [[NSMutableArray alloc] init];
            NSUInteger total = 0;
            while ((oneBim = select.nextObject)) {
                if ([oneBim.simId isEqualToNumber:@(ACCMomentBIMResultDefaultSimId)]) {
                    continue;
                }
                
                VEAIMomentMaterialInfo *oneMaterialInfo = [oneBim createMaterialInfo];
                [input addObject:oneMaterialInfo];
                
                total += 1;
                if (self.scanLimitCount > 0 &&
                    total > self.scanLimitCount) {
                    break;
                }
            }
            
            if (input.count == 0) {
                [completions enumerateObjectsUsingBlock:^(ACCMomentATIMManagerAIMCompletion  _Nonnull oneCompletion, NSUInteger idx, BOOL * _Nonnull stop) {
                    oneCompletion(nil, nil);
                }];
                return;
            }
            
            NSError *error;
            CFAbsoluteTime ctime = CFAbsoluteTimeGetCurrent();
            VEAlgorithmInputMomentAIM *aimInput = [[VEAlgorithmInputMomentAIM alloc] init];
            aimInput.materialInfos = input;
            aimInput.templateId = 0;
            aimInput.useInfo = [VEAIMomentUserInfo new];
            
            VEAlgorithmRuntimeParams *params = [VEAlgorithmRuntimeParams new];
            params.mode = VEAlgorithmModeAim;
            params.serviceIndex = -1;
            
            VEAlgorithmInput *algorithmInput = [[VEAlgorithmInput alloc] init];
            algorithmInput.momentAIMInput = aimInput;
            
            VEAlgorithmOutput *output = [self.aiAlgorithm getAlgorithmResult:algorithmInput runtimeParams:params error:&error];
            NSArray<VEAIMomentMoment*> *aiMomentList = output.momentAIMOutput.momentList;
            NSString *momentIds = [[aiMomentList valueForKey:@"identity"] componentsJoinedByString:@","];
            NSString *momentTypes = [[aiMomentList valueForKey:@"type"] componentsJoinedByString:@","];
            CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
            NSMutableDictionary *extra =
            [NSMutableDictionary dictionaryWithDictionary:@{
                @"duration": @(gap),
                @"moment_id": momentIds? : @"",
                @"moment_type": momentTypes? : @""
            }];
            if (error.userInfo[VEAIMomentErrorCodeKey]) {
                extra[@"moment_errorcode"] = error.userInfo[VEAIMomentErrorCodeKey];
            }
            [ACCMonitor() trackService:@"moment_aim_access"
                                status:aiMomentList? 0: 1
                                 extra:extra];
            
            NSMutableArray *uids = [[NSMutableArray alloc] init];
            NSMutableArray<ACCMomentAIMomentModel *> *modelResult = [[NSMutableArray alloc] init];
            [aiMomentList enumerateObjectsUsingBlock:^(VEAIMomentMoment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                ACCMomentAIMomentModel *model = [[ACCMomentAIMomentModel alloc] init];
                model.identity = obj.identity;
                model.type = obj.type;
                model.title = obj.title;
                model.version = obj.version;
                model.templateId = obj.templateId;
                model.momentSource = obj.momentSource;
                model.coverUid = obj.coverId;
                model.uids = obj.materialIds;
                model.extra = obj.extra;
                model.effectId = obj.effectId;
                
                [uids addObject:@(obj.coverId)];
                [uids addObjectsFromArray:obj.materialIds];

                [modelResult addObject:model];
            }];

            NSMutableArray *coverUids = [[NSMutableArray alloc] init];
            [self.dataProvider loadLocalIdentifiersWithUids:uids resultBlock:^(NSDictionary<NSNumber *,NSString *> * _Nullable result, NSError * _Nullable error) {
                [modelResult enumerateObjectsUsingBlock:^(ACCMomentAIMomentModel * _Nonnull oneModel, NSUInteger idx, BOOL * _Nonnull stop) {
                    VEAIMomentMoment *oneAIMoment = aiMomentList[idx];
                    NSMutableArray *materialIds = [[NSMutableArray alloc] init];

                    [oneAIMoment.materialIds enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSString *oneId = result[obj];
                        if (oneId) {
                            [materialIds addObject:oneId];
                        }
                    }];

                    oneModel.materialIds = materialIds;
                    oneModel.coverMaterialId = result[@(oneAIMoment.coverId)];
                    [coverUids addObject:@(oneAIMoment.coverId)];
                }];
                
                [self.dataProvider loadBIMWithUids:coverUids resultBlock:^(NSArray<ACCMomentBIMResult *> * _Nullable coverResults, NSError * _Nullable error) {
                    [coverResults enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        ACCMomentAIMomentModel *oneModel = modelResult[idx];
                        oneModel.coverReframes = ({
                            NSMutableArray *reframes = [[NSMutableArray alloc] init];
                            [obj.reframeInfos enumerateObjectsUsingBlock:^(VEAIMomentReframeInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                if (obj.score >= ReFrameScoreDefault) {
                                    [reframes addObject:[[ACCMomentReframe alloc] initWithReframe:obj.frame]];
                                } else {
                                    [reframes addObject:[NSNull null]];
                                }
                            }];
                            
                            reframes;
                        });
                    }];

                    [completions enumerateObjectsUsingBlock:^(ACCMomentATIMManagerAIMCompletion  _Nonnull oneCompletion, NSUInteger idx, BOOL * _Nonnull stop) {
                        oneCompletion(modelResult, nil);
                    }];
                }];
            }];
        });
    }];
}

- (void)requestTIMResultWithAIMoment:(ACCMomentAIMomentModel *)aiMoment
                           usedPairs:(NSArray<VEAIMomentTemplatePair *> *)usedPairs
                          completion:(ACCMomentATIMManagerTIMCompletion)completion
{
    if (!completion) {
        return;
    }
    
    if (!self.timIsReady) {
        self.timCompletion = completion;
        self.templatePairs = usedPairs;
        self.templateReferMoment = aiMoment;
        return;
    }
    
    [self.dataProvider loadBIMWithLocalIdentifiers:aiMoment.materialIds
                                       resultBlock:^(NSArray<ACCMomentBIMResult *> * _Nullable results, NSError * _Nullable error) {
         dispatch_async(self.atimQueue, ^{
             NSMutableArray *input = [[NSMutableArray alloc] init];
             [results enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                 VEAIMomentMaterialInfo *m = [obj createMaterialInfo];
                 [input addObject:m];
             }];
             
             NSMutableDictionary *materialsMap = [[NSMutableDictionary alloc] init];
             [results enumerateObjectsUsingBlock:^(ACCMomentBIMResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                 materialsMap[@(obj.uid)] = obj;
             }];

             VEAIMomentTemplateRec *templateRec = [[VEAIMomentTemplateRec alloc] init];
             templateRec.coverId = aiMoment.coverUid;
             templateRec.currentMomentId = aiMoment.identity;
             templateRec.usedPairs = usedPairs;

             CFAbsoluteTime ctime = CFAbsoluteTimeGetCurrent();
             NSError *error;
             VEAlgorithmInput *algorithmInput = [VEAlgorithmInput new];

             VEAlgorithmInputMomentTIM *timInput = [VEAlgorithmInputMomentTIM new];
             timInput.materialInfos = input;
             timInput.templateId = aiMoment.templateId;
             timInput.useInfo = [VEAIMomentUserInfo new];
             timInput.recInfo = templateRec;

             algorithmInput.momentTIMInput = timInput;

             VEAlgorithmRuntimeParams *params = [VEAlgorithmRuntimeParams new];
             params.mode = VEAlgorithmModeTim;
             params.serviceIndex = -1;
             
             VEAlgorithmOutput *output = [self.aiAlgorithm getAlgorithmResult:algorithmInput runtimeParams:params error:&error];
             NSArray<VEAIMomentTemplateInfo *> *timResult = output.momentTIMOutput.templateList;

             NSString *templateIds = [[timResult valueForKey:@"templateId"] componentsJoinedByString:@","];
             CFAbsoluteTime gap = CFAbsoluteTimeGetCurrent() - ctime;
             NSMutableDictionary *extra =
             [NSMutableDictionary dictionaryWithDictionary:@{
                 @"duration": @(gap),
                 @"template_id": templateIds? : @""
             }];
             if (error.userInfo[VEAIMomentErrorCodeKey]) {
                 extra[@"moment_errorcode"] = error.userInfo[VEAIMomentErrorCodeKey];
             }
             [ACCMonitor() trackService:@"moment_tim_access"
                                 status:timResult? 0: 1
                                  extra:extra];
             
             NSMutableArray *templates = [[NSMutableArray alloc] init];
             [timResult enumerateObjectsUsingBlock:^(VEAIMomentTemplateInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                 ACCMomentTemplateModel *oneTemplate = [[ACCMomentTemplateModel alloc] init];
                 oneTemplate.templateId = (NSInteger)obj.templateId;
                 oneTemplate.templateType = (obj.source == 1? ACCMomentTemplateType_CutSame: ACCMomentTemplateType_Classic);
                 
                 NSMutableArray *segInfos = [[NSMutableArray alloc] init];
                 [obj.segInfos enumerateObjectsUsingBlock:^(VEAIMomentMaterialSegInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     ACCMomentBIMResult *bim = materialsMap[@(obj.materialId)];
                     ACCMomentMaterialSegInfo *seg = [[ACCMomentMaterialSegInfo alloc] initWithSegInfo:obj];
                     seg.materialId = bim.localIdentifier;
                     
                     [segInfos addObject:seg];
                 }];
                 
                 oneTemplate.segInfos = segInfos;
                 [templates addObject:oneTemplate];
             }];
             
             completion(templates, nil);
         });
    }];
}

#pragma mark - Properties
- (BOOL)aimIsReady
{
    return (self.configJson.length > 0);
}

- (void)setConfigJson:(NSString *)configJson
{
    if (_configJson != configJson) {
        _configJson = configJson;
        
        if (_configJson && self.prepareAIMCompletions.count) {
            NSArray *cpAIMCompletions = [self.prepareAIMCompletions copy];
            [self.prepareAIMCompletions removeAllObjects];
            [self realRequestAIMResultWithCompletions:cpAIMCompletions];
        }
    }
}

- (void)setTimIsReady:(BOOL)timIsReady
{
    if (_timIsReady != timIsReady) {
        _timIsReady = timIsReady;
        
        if (_timIsReady && self.timCompletion && self.templateReferMoment) {
            [self requestTIMResultWithAIMoment:self.templateReferMoment
                                     usedPairs:self.templatePairs
                                    completion:self.timCompletion];
            self.timCompletion = nil;
            self.templatePairs = nil;
            self.templateReferMoment = nil;
        }
    }
}

- (NSString *)templateReccommentAlgorithmModelPath
{
    if (self.timUseEffectPlatform && self.timIsReady) {
        return @"";
    } else {
        NSString *tempRecName = [[NSString alloc] initWithContentsOfFile:ACCMomentATIMManagerTIMModelNamePath() encoding:NSUTF8StringEncoding error:nil];
        if (tempRecName.length) {
            return ACCMomentATIMManagerTIMModelPath(tempRecName);
        }
    }
    
    return @"";
}

- (void)setPannelName:(NSString *)pannelName
{
    if (pannelName.length) {
        if (![_pannelName isEqualToString:pannelName]) {
            _pannelName = [pannelName copy];
            
            self.configJson = [[NSString alloc] initWithContentsOfFile:ACCMomentATIMManagerAIMConfigPath(_pannelName) encoding:NSUTF8StringEncoding error:nil];
            self.aiAlgorithm = nil;
        }
    }
}

#pragma mark - Lazy load
- (VEAIMomentAlgorithm *)aiAlgorithm
{
    if (!_aiAlgorithm) {
        VEAlgorithmConfig *config = [[VEAlgorithmConfig alloc] init];
        config.configPath = self.configJson;
        config.resourceFinder = [IESMMParamModule getResourceFinder];
        config.serviceCount = 1;
        config.tempRecPath = self.templateReccommentAlgorithmModelPath;
        config.superParams = 0b11111101111;
        config.initType = VEAlgorithmInitTypeMoment;
        _aiAlgorithm = [[VEAIMomentAlgorithm alloc] initWithConfig:config];
    }
    
    return _aiAlgorithm;
}

@end

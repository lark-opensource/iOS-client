//
//  IESEffectModel.m
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/29.
//

#import "IESEffectModel.h"
#import "IESEffectDefines.h"
#import "EffectPlatformBookMark.h"

#import <EffectPlatformSDK/IESEffectManager.h>
#import "IESEffectDecryptUtil.h"
static NSString * const kARRequriment = @"faceDetect";

@interface IESEffectModel ()

@property (nonatomic, assign) IESEffectModelEffectType effectType;
@property (nonatomic, strong) NSArray<NSString *> *childrenIds;
@property (nonatomic, strong) NSArray<IESEffectModel *> *childrenEffects;
@property (nonatomic, copy) NSString *parentEffectID;

@property (nonatomic, copy) NSArray<NSString *> *types; // 道具类型数组
@property (nonatomic, readwrite, copy) NSArray<NSString *> *typesSec;
@property (nonatomic, readwrite, copy) NSArray<NSString *> *algorithmRequirements;
@property (nonatomic, readwrite, copy) NSArray<NSString *> *algorithmRequirementsSec;

@property (nonatomic, copy) NSString *originalEffectID; // 特效 id 原始值
@property (nonatomic, copy) NSString *effectIdentifier; // 特效 id
@property (nonatomic, copy) NSString *sourceIdentifier; // 用于唯一标识特效
@property (nonatomic, copy) NSString *md5;

@property (nonatomic, copy) NSString *modelNamesJsonStr; // 模型名称json
@property (nonatomic, copy) NSString *modelNamesJsonStrSec;
@property (nonatomic, copy) NSDictionary *modelNames; // 模型名称
@property (nonatomic, copy) NSString *sdkExtra;  // sdkExtra.

@end

@implementation IESEffectModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"effectName":@"name",
             @"resourceID": @"resource_id",
             @"hintLabel":@"hint",
             @"gradeKey":@"grade_key",
             @"composerParams":@"composer_params",
             @"sdkVersion":@"sdk_version",
             @"appVersion":@"app_version",
             @"fileDownloadURLs":@"file_url.url_list",
             @"hintIconDownloadURLs":@"hint_icon.url_list",
             @"hintIconURI":@"hint_icon.uri",
             @"iconDownloadURLs":@"icon_url.url_list",
             @"sourceIdentifier":@"id",
             @"md5":@"file_url.uri",
             @"effectIdentifier":@"effect_id",
             @"originalEffectID":@"original_effect_id",
             @"devicePlatform":@"device_platform",
             @"types":@"types",
             @"typesSec":@"types_sec",
             @"fileDownloadURI":@"file_url.uri",
             @"iconDownlaodURI":@"icon_url.uri",
             @"tags":@"tags",
             @"tagsUpdatedTimeStamp":@"tags_updated_at",
             @"effectUpdateTimeStamp":@"updated_at",
             @"effectType" : @"effect_type",
             @"childrenIds" : @"children",
             @"parentEffectID" : @"parent",
             @"source" : @"source",
             @"designerId" : @"designer_id",
             @"schema" : @"schema",
             @"algorithmRequirements":@"requirements",
             @"algorithmRequirementsSec":@"requirements_sec",
             @"extra" : @"extra",
             @"musicIDs" : @"music",
             @"isCommerce" : @"is_busi",
             @"iopId" : @"iop_id",
             @"isIop" : @"is_iop",
             @"isChecked" : @"is_checked",
             @"isBuildin" : @"is_buildin",
             @"designerEncryptedId" : @"designer_encrypted_id",
             @"sdkExtra" : @"sdk_extra",
             @"adRawData" : @"ad_raw_data",
             @"resourceId" : @"resource_id",
             @"bindIDs" : @"bind_ids",
             @"ptime" : @"ptime",
             @"panelName":@"panel",
             @"modelNamesJsonStrSec":@"model_names_sec",
             @"modelNamesJsonStr": @"model_names",
             @"hintFileURI":@"hint_file.uri",
             @"hintFileURLs":@"hint_file.url_list",
             @"hintFileFormat":@"hint_file_format",
             @"challengeIDs": @"challenge",
             @"use_number": @"use_number",
             @"videoPlayURLs": @"videoPlayURLs",
             @"nickName": @"nickname",
             @"avatarThumbURI": @"avatar_thumb.uri",
             @"avatarThumbURLs": @"avatar_thumb.url_list",
            };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {
    if (self = [super initWithDictionary:dictionaryValue error:error]) {
        if (self.typesSec.count > 0 && self.types.count == 0) {
            self.types = [IESEffectDecryptUtil decryptArray:self.typesSec];
        }
        if (self.algorithmRequirementsSec.count > 0 && self.algorithmRequirements.count == 0) {
            self.algorithmRequirements = [IESEffectDecryptUtil decryptArray:self.algorithmRequirementsSec];
        }
        if (self.modelNamesJsonStrSec.length > 0 && self.modelNamesJsonStr.length == 0) {
            self.modelNamesJsonStr = [IESEffectDecryptUtil decryptString:self.modelNamesJsonStrSec];
        }
        [self updateModelNames];
        // 道具依赖的算法模型都是通过把算法requirement名称放入algorithmRequirements数组中来下载的。
        // 如果 types 数组包含 AR 字段，表示这是一个 AR 道具。
        // AR 道具的 algorithmRequirements 里并不包含 faceDetect 这个 requirement，需要外部单独调用
        // [EffectPlatform downloadRequirements:@[@"faceDetect"] completion:nil]; 去下载这个算法模型。
        // 此处通过把 faceDetect 放入 algorithmRequirements 统一算法模型的下载。
        if ([self.types containsObject:IESEffectTypeAR]) {
            if (![self.algorithmRequirements containsObject:kARRequriment]) {
                NSMutableArray *requirements = [[NSMutableArray alloc] init];
                [requirements addObject:kARRequriment];
                if (self.algorithmRequirements.count > 0) {
                    [requirements addObjectsFromArray:self.algorithmRequirements];
                }
                self.algorithmRequirements = [requirements copy];
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isEqual:(IESEffectModel *)object {
    if (!object || ![object isKindOfClass:[IESEffectModel class]]) {
        return NO;
    }
    if (!self.sourceIdentifier || !object.sourceIdentifier) {
        return NO;
    }
    return [object.sourceIdentifier isEqualToString:self.sourceIdentifier];
    
}

- (NSUInteger)hash {
    return self.sourceIdentifier.hash;
}

- (void)updateChildrenEffectsWithCollection:(NSArray<IESEffectModel *> *)collection {
    if (self.effectType == IESEffectModelEffectTypeNormal) {
        self.childrenEffects = @[];
        return;
    }
    
    NSMutableArray<IESEffectModel *> *childrenEffects = [NSMutableArray arrayWithCapacity:self.childrenEffects.count];
    NSMutableDictionary<NSString *, IESEffectModel *> *dic = [NSMutableDictionary dictionary];
    for (IESEffectModel *effect in collection) {
        if ([effect.effectIdentifier isKindOfClass:[NSString class]] && effect.effectIdentifier.length) {
            dic[effect.effectIdentifier] = effect;
        }
    }
    for (NSString *effectID in self.childrenIds) {
        if (![effectID isKindOfClass:[NSString class]] || !effectID.length) {
            continue;
        }
        IESEffectModel *effect = dic[effectID];
        if (effect) {
            [childrenEffects addObject:effect];
        }
    }
    self.childrenEffects = [childrenEffects copy];
}

- (void)updateChildrenEffectsWithCollectionDictionary:(NSDictionary<NSString *,IESEffectModel *> *)collectionDictionay {
    if (IESEffectModelEffectTypeNormal == self.effectType) {
        self.childrenEffects = @[];
        return;
    }
    
    if (collectionDictionay.count > 0 && self.childrenIds.count > 0) {
        NSMutableArray<IESEffectModel *> *childrenEffects = [[NSMutableArray alloc] initWithCapacity:self.childrenIds.count];
        for (NSString *effectID in self.childrenIds) {
            if (![effectID isKindOfClass:[NSString class]] || !effectID.length) {
                continue;
            }
            IESEffectModel *effect = collectionDictionay[effectID];
            if (effect) {
                [childrenEffects addObject:effect];
            }
        }
        self.childrenEffects = [childrenEffects copy];
    }
}

- (void)updateTypes:(NSArray<NSString *> *)types;
{
    self.types = [types copy];
}

- (void)updateSDKExtra:(NSString *)sdkExtra
{
    self.sdkExtra = [sdkExtra copy];
}

- (void)setURLPrefix:(NSArray<NSString *> *)URLPrefix {
    if (URLPrefix.count > 0) {
        NSMutableArray *fileDownloadURLs = [[NSMutableArray alloc] init];
        NSMutableArray *iconDownloadURLs = [[NSMutableArray alloc] init];
        
        NSString *fileDownloadURI = self.fileDownloadURI;
        NSString *iconDownloadURI = self.iconDownlaodURI;
        
        if (fileDownloadURI) {
            [URLPrefix enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *fileDownloadURL = [obj stringByAppendingString:fileDownloadURI];
                [fileDownloadURLs addObject:fileDownloadURL];
            }];
        }
        
        if (iconDownloadURI) {
            [URLPrefix enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *iconDownloadURL = [obj stringByAppendingString:iconDownloadURI];
                [iconDownloadURLs addObject:iconDownloadURL];
            }];
        }
        
        self.fileDownloadURLs = [fileDownloadURLs copy];
        self.iconDownloadURLs = [iconDownloadURLs copy];
    }
}

- (void)updateModelNames {
    if (self.modelNamesJsonStr && self.modelNamesJsonStr.length > 0 && !self.modelNames) {
        NSData *jsonData = [self.modelNamesJsonStr dataUsingEncoding:NSUTF8StringEncoding];
        id jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                      options:NSJSONReadingMutableContainers
                                                        error:nil];
        if ([jsonDict isKindOfClass:[NSDictionary class]]) {
            self.modelNames = jsonDict;
        }
    }
}

@end

@implementation IESEffectModel (EffectDownloader)

- (NSString *)p_filePath {
    
    if ([self checkAlgorithmRelatedFieldsDecryptFailed]) {
        return nil;
    }
    
    return [[IESEffectManager manager] effectPathForEffectModel:self];
}

- (BOOL)checkAlgorithmRelatedFieldsDecryptFailed {
    BOOL isRequirementsDecryptFailed = self.algorithmRequirementsSec.count > 0 && self.algorithmRequirements.count == 0;
    BOOL isModelNamesJsonStrDecryptFailed = self.modelNamesJsonStrSec.length > 0 && self.modelNamesJsonStr.length == 0;
    return isRequirementsDecryptFailed || isModelNamesJsonStrDecryptFailed;
}

- (NSString *)filePath
{
    NSString *path = [self p_filePath];
    if (path) {
        [[IESEffectManager manager] updateUseCountForEffect:self byValue:1];
    }
    return path;
}

- (BOOL)downloaded
{
    return [self p_filePath] != nil;
}

@end


@implementation IESEffectModel (BookMark)

- (void)markAsReaded
{
    [EffectPlatformBookMark markReadForEffect:self];
}

- (BOOL)showRedDotWithTag:(NSString *)tag
{
    if (tag && tag.length > 0 && [self.tags containsObject:tag]) {
        return ![EffectPlatformBookMark isReadForEffect:self];
    }
    return NO;
}

@end

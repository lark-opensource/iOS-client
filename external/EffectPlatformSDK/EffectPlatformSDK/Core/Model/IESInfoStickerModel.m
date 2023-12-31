//
//  IESEffectInfoStickerResponseModel.m
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/1/5.
//

#import "IESInfoStickerModel.h"
#import "IESEffectModel.h"
#import "IESThirdPartyStickerModel.h"
#import "IESEffectDecryptUtil.h"
#import "IESEffectLogger.h"

@interface IESInfoStickerModel () {
    IESEffectModel *_effectModel;
    IESThirdPartyStickerModel *_thirdPartyStickerModel;
}

@property (nonatomic, readonly, copy) NSArray<NSString *> *typesSec;
@property (nonatomic, readonly, copy) NSArray<NSString *> *algorithmRequirementsSec;
@property (nonatomic, readonly, copy) NSString *modelNamesJsonStrSec;

@property (nonatomic, readwrite, copy) NSArray<NSString *> *types; // 道具类型数组
@property (nonatomic, readwrite, copy) NSArray<NSString *> *algorithmRequirements;
@property (nonatomic, readwrite, copy) NSString *modelNamesJsonStr; // 模型名称json
@property (nonatomic, readwrite, copy) NSDictionary *modelNames; // 模型名称
@property (atomic, readwrite, copy) NSArray<IESInfoStickerModel *> *childrenStickers;

@end

@implementation IESInfoStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"effectName":@"loki_effect.name",
        @"hintLabel":@"loki_effect.hint",
        @"hintIconURI":@"loki_effect.hint_icon.uri",
        @"hintIconDownloadURLs":@"loki_effect.hint_icon.url_list",
        @"sdkVersion":@"loki_effect.sdk_version",
        @"appVersion":@"loki_effect.app_version",
        @"md5":@"loki_effect.file_url.uri",
        @"fileDownloadURLs":@"loki_effect.file_url.url_list",
        @"iconDownlaodURI":@"loki_effect.icon_url.uri",
        @"iconDownloadURLs":@"loki_effect.icon_url.url_list",
        @"effectIdentifier":@"loki_effect.effect_id",
        @"devicePlatform":@"loki_effect.device_platform",
        @"types":@"loki_effect.types",
        @"typesSec":@"loki_effect.types_sec",
        @"tags":@"loki_effect.tags",
        @"tagsUpdatedTimeStamp":@"loki_effect.tags_updated_at",
        @"parentEffectID" : @"loki_effect.parent",
        @"childrenIds" : @"loki_effect.children",
        @"effectType" : @"loki_effect.effect_type",
        @"musicIDs" : @"loki_effect.music",
        @"lokiSource" : @"loki_effect.source",
        @"designerId" : @"loki_effect.designer_id",
        @"schema" : @"loki_effect.schema",
        @"algorithmRequirements":@"loki_effect.requirements",
        @"algorithmRequirementsSec":@"loki_effect.requirements_sec",
        @"extra" : @"loki_effect.extra",
        @"isCommerce" : @"loki_effect.is_busi",
        @"iopId" : @"loki_effect.iop_id",
        @"isIop" : @"loki_effect.is_iop",
        @"designerEncryptedId" : @"loki_effect.designer_encrypted_id",
        @"sdkExtra" : @"loki_effect.sdk_extra",
        @"resourceID": @"loki_effect.resource_id",
        @"adRawData" : @"loki_effect.ad_raw_data",
        @"bindIDs" : @"loki_effect.bind_ids",
        @"ptime" : @"loki_effect.ptime",
        @"gradeKey":@"loki_effect.grade_key",
        @"composerParams":@"loki_effect.composer_params",
        @"panelName":@"loki_effect.panel",
        @"modelNamesJsonStrSec":@"loki_effect.model_names_sec",
        @"modelNamesJsonStr": @"loki_effect.model_names",
        @"hintFileFormat":@"loki_effect.hint_file_format",
        @"hintFileURI":@"loki_effect.hint_file.uri",
        @"hintFileURLs":@"loki_effect.hint_file.url_list",
        @"challengeIDs": @"loki_effect.challenge",
        @"dataSource":@"source",
        @"identifier" : @"sticker.id",
        @"title" : @"sticker.title",
        @"thumbnailSticker" : @"sticker.thumbnail_sticker",
        @"sticker" : @"sticker.sticker",
        @"clickURL" : @"sticker.click_url",
        @"thirdPartyExtra" : @"sticker.extra"
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
    }
    return self;
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

- (void)setURLPrefix:(NSArray<NSString *> *)urlPrefix {
    if (urlPrefix.count > 0) {
        NSMutableArray *fileDownloadURLs = [[NSMutableArray alloc] init];
        NSMutableArray *iconDownloadURLs = [[NSMutableArray alloc] init];
        
        NSString *fileDownloadURI = self.md5;
        NSString *iconDownloadURI = self.iconDownlaodURI;
        
        if (fileDownloadURI) {
            [urlPrefix enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *fileDownloadURL = [obj stringByAppendingString:fileDownloadURI];
                [fileDownloadURLs addObject:fileDownloadURL];
            }];
        }
        
        if (iconDownloadURI) {
            [urlPrefix enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *iconDownloadURL = [obj stringByAppendingString:iconDownloadURI];
                [iconDownloadURLs addObject:iconDownloadURL];
            }];
        }
        
        self.fileDownloadURLs = [fileDownloadURLs copy];
        self.iconDownloadURLs = [iconDownloadURLs copy];
    }
}

- (void)updateChildrenStickersWithCollection:(NSArray<IESInfoStickerModel *> *)collection
{
    if (self.dataSource == IESInfoStickerModelSourceThirdParty) {
        self.childrenStickers = @[];
        return;
    }
    
    NSMutableArray<IESInfoStickerModel *> *childrenStickers = [NSMutableArray arrayWithCapacity:self.childrenStickers.count];
    NSMutableDictionary<NSString *, IESInfoStickerModel *> *dic = [NSMutableDictionary dictionary];
    for (IESInfoStickerModel *sticker in collection) {
        if ([sticker.stickerIdentifier isKindOfClass:[NSString class]] && sticker.stickerIdentifier.length) {
            dic[sticker.sticker] = sticker;
        }
    }
    for (NSString *stickerId in self.childrenIds) {
        if (![stickerId isKindOfClass:[NSString class]] || !stickerId.length) {
            continue;
        }
        IESInfoStickerModel *sticker = dic[sticker];
        if (sticker) {
            [childrenStickers addObject:sticker];
        }
    }
    self.childrenStickers = [childrenStickers copy];
}

- (NSString *)stickerIdentifier {
    switch (self.dataSource) {
        case IESInfoStickerModelSourceLoki:
            return self.effectIdentifier;
        case IESInfoStickerModelSourceThirdParty:
            return self.identifier;
        default:
            return @"";
    }
}

- (NSString *)filePath {
    switch (self.dataSource) {
        case IESInfoStickerModelSourceLoki:
            return [[self effectModel] filePath];
        case IESInfoStickerModelSourceThirdParty:
            return [[self thirdPartyStickerModel] filePath];
        default:
            NSAssert(NO, @"dataSource of InfoSticker shoule be one or two");
            return nil;
    }
}

- (BOOL)downloaded {
    switch (self.dataSource) {
        case IESInfoStickerModelSourceLoki:
            return [[self effectModel] downloaded];
        case IESInfoStickerModelSourceThirdParty:
            return [[self thirdPartyStickerModel] downloaded];
        default:
            NSAssert(NO, @"dataSource of InfoSticker shoule be one or two");
            return NO;
    }
}

- (IESEffectModel *)effectModel {
    if (!_effectModel && self.dataSource == IESInfoStickerModelSourceLoki) {
        NSDictionary *jsonData = [MTLJSONAdapter JSONDictionaryFromModel:self error:nil];
        NSDictionary *lokiEffectData = [jsonData objectForKey:@"loki_effect"];
        if (lokiEffectData && [lokiEffectData isKindOfClass:NSDictionary.class]) {
            NSError *error = nil;
            _effectModel = [MTLJSONAdapter modelOfClass:[IESEffectModel class]
                                     fromJSONDictionary:lokiEffectData
                                                  error:&error];
            if (error) {
                IESEffectLogError(@"IESInfoStickerModel transforms to IESEffectModel failed with error:%@", error);
            }
        }
    }
    return _effectModel;
}

- (IESThirdPartyStickerModel *)thirdPartyStickerModel {
    if (!_thirdPartyStickerModel && self.dataSource == IESInfoStickerModelSourceThirdParty) {
        NSDictionary *jsonData = [MTLJSONAdapter JSONDictionaryFromModel:self error:nil];
        NSDictionary *thirdPartyStickerData = [jsonData objectForKey:@"sticker"];
        if (thirdPartyStickerData && [thirdPartyStickerData isKindOfClass:NSDictionary.class]) {
            NSError *error = nil;
            _thirdPartyStickerModel = [MTLJSONAdapter modelOfClass:[IESThirdPartyStickerModel class]
                                                fromJSONDictionary:thirdPartyStickerData
                                                             error:&error];
            if (error) {
                IESEffectLogError(@"IESInfoStickerModel transforms to IESThirdPartyStickerModel failed with error:%@", error);
            }
        }
    }
    return _thirdPartyStickerModel;
}

@end

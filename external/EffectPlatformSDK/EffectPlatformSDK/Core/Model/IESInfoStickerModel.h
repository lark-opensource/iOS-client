//
//  IESEffectInfoStickerResponseModel.h
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/1/5.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectDefines.h>
#import <EffectPlatformSDK/IESThirdPartyStickerInfoModel.h>
#import <Mantle/Mantle.h>
NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
@class IESThirdPartyStickerModel;

@interface IESInfoStickerModel : MTLModel<MTLJSONSerializing>

//lokiEffect property
@property (nonatomic, readonly) NSString *effectName; // 道具名称
@property (nonatomic, readonly, copy) NSString *hintLabel; // 特效提示文案
@property (nonatomic, readonly, copy) NSString *hintIconURI; // 特效提示图标md5
@property (nonatomic, readonly, copy) NSArray<NSString *> *hintIconDownloadURLs; // 特效提示图标地址
@property (nonatomic, readonly, copy) NSString *sdkVersion; // 最低兼容的 effect id 版本号
@property (nonatomic, readonly, copy) NSString *appVersion; // 生效的最低 app 版本号
@property (nonatomic, copy) NSString *md5;
@property (nonatomic, copy) NSArray<NSString *> *fileDownloadURLs; // 特效文件地址
@property (nonatomic, copy) NSString *iconDownlaodURI;
@property (nonatomic, copy) NSArray<NSString *> *iconDownloadURLs; // 特效图标地址
@property (nonatomic, readonly, copy) NSString *sourceIdentifier; // 用于唯一标识特效
@property (nonatomic, readonly, copy) NSString *effectIdentifier; // 特效 id
@property (nonatomic, readonly, copy) NSString *devicePlatform; // 设备平台
@property (nonatomic, readonly, copy) NSArray<NSString *> *types; // 道具类型数组
@property (nonatomic, readonly) NSArray<NSString *> *tags; // 标签值
@property (nonatomic, readonly) NSString *tagsUpdatedTimeStamp; // 标签更新时间

@property (nonatomic, readonly, copy) NSString *parentEffectID;
@property (atomic, readonly, copy) NSArray<IESInfoStickerModel *> *childrenStickers;
@property (nonatomic, readonly, copy) NSArray<NSString *> *childrenIds;
@property (nonatomic, readonly, assign) IESEffectModelEffectType effectType;

@property (nonatomic, readonly, copy) NSArray<NSString *> *musicIDs; // 音乐id列表
@property (nonatomic, readonly, assign) IESEffectModelEffectSource lokiSource;
@property (nonatomic, readonly, copy) NSString *designerId;
@property (nonatomic, readonly, copy) NSString *schema;
@property (nonatomic, readonly, copy) NSArray<NSString *> *algorithmRequirements;
@property (nonatomic, readonly, copy) NSString *extra; // extra字段存放额外的信息，JSON内容的string.

@property (nonatomic, readonly, assign) BOOL isCommerce; // 是否是商业化贴纸
@property (nonatomic, readonly, copy) NSString *iopId;
@property (nonatomic, readonly, assign) BOOL isIop;
@property (nonatomic, readonly, copy) NSString *designerEncryptedId; // 设计师加密id

@property (nonatomic, readonly, copy) NSString *sdkExtra;
@property (nonatomic, readonly, copy) NSString *resourceID;
@property (nonatomic, readonly, copy) NSString *adRawData;

@property (nonatomic, readonly, copy) NSArray<NSString *> *bindIDs;
@property (nonatomic, readonly, assign) long long ptime; // 特效发布时间
@property (nonatomic, readonly, copy) NSString *gradeKey; //分级包
@property (nonatomic, readonly, copy) NSString *composerParams; // 美颜特效composer_params
@property (nonatomic, copy) NSString *panelName; // Panel the sticker belongs to.

@property (nonatomic, readonly, copy) NSDictionary *modelNames; // 模型名称

@property (nonatomic, readonly, assign) NSInteger hintFileFormat; // 提示文件格式(包括:文本、PNG、gif、lottie)
@property (nonatomic, readonly, copy) NSString *hintFileURI; // 提示文件URI
@property (nonatomic, readonly, copy) NSArray<NSString *> *hintFileURLs; // 提示文件urlList
@property (nonatomic, readonly, copy, nullable) NSArray<NSString *> *challengeIDs; // 绑定挑战id eg. ["123", "456"]

@property (nonatomic, readonly, copy) NSString *identifier;
//1.from loki 2.from third party
@property (nonatomic, readonly, assign) IESInfoStickerModelSource dataSource;

//third party property
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, strong) IESThirdPartyStickerInfoModel *thumbnailSticker;
@property (nonatomic, readonly, strong) IESThirdPartyStickerInfoModel *sticker;
@property (nonatomic, readonly, copy) NSString *clickURL;
@property (nonatomic, readonly, copy) NSString *thirdPartyExtra;

- (NSString *)stickerIdentifier;
- (nullable NSString *)filePath;
- (BOOL)downloaded;
- (void)setURLPrefix:(NSArray<NSString *> *)urlPrefix;
- (void)updateChildrenStickersWithCollection:(NSArray<IESInfoStickerModel *> *)collection;

- (nullable IESEffectModel *)effectModel;
- (nullable IESThirdPartyStickerModel *)thirdPartyStickerModel;

@end

NS_ASSUME_NONNULL_END

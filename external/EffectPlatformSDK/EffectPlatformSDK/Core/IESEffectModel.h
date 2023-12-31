//
//  IESEffectModel.h
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/29.
//

#import <Foundation/Foundation.h>
#import "IESEffectDefines.h"
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, readonly) NSString *effectName; // 道具名称
@property (nonatomic, copy) NSString *resourceID; // 道具资源ID
@property (nonatomic, readonly, copy) NSString *gradeKey; //分级包
@property (nonatomic, readonly, copy) NSString *composerParams; // 美颜特效composer_params
@property (nonatomic, readonly, copy) NSString *hintLabel; // 特效提示文案
@property (nonatomic, readonly, copy) NSString *sdkVersion; // 最低兼容的 effect id 版本号
@property (nonatomic, readonly, copy) NSString *appVersion; // 生效的最低 app 版本号
@property (nonatomic, copy) NSArray<NSString *> *fileDownloadURLs; // 特效文件地址
@property (nonatomic, readonly, copy) NSArray<NSString *> *hintIconDownloadURLs; // 特效提示图标地址
@property (nonatomic, readonly, copy) NSString *hintIconURI; // 特效提示图标md5
@property (nonatomic, copy) NSArray<NSString *> *iconDownloadURLs; // 特效图标地址
@property (nonatomic, copy) NSString *fileDownloadURI;
@property (nonatomic, copy) NSString *iconDownlaodURI;
@property (nonatomic, readonly, copy) NSString *originalEffectID; // 特效id原始值（与特效ID映射，某些场合需要该ID来与之校准）
@property (nonatomic, readonly, copy) NSString *effectIdentifier; // 特效 id
@property (nonatomic, readonly, copy) NSString *sourceIdentifier; // 用于唯一标识特效
@property (nonatomic, readonly, copy) NSString *md5;
@property (nonatomic, readonly, copy) NSString *devicePlatform; // 设备平台
@property (nonatomic, readonly, copy) NSArray<NSString *> *types; // 道具类型数组
@property (nonatomic, readonly) NSArray<NSString *> *tags; // 标签值
@property (nonatomic, readonly) NSString *tagsUpdatedTimeStamp; // 标签更新时间
@property (nonatomic, readonly, copy) NSString *effectUpdateTimeStamp; // 特效更新时间，Studio制作的贴纸上传到特效后台的时间
@property (nonatomic, readonly, assign) IESEffectModelEffectType effectType;
@property (nonatomic, readonly, strong) NSArray<NSString *> *childrenIds;
@property (nonatomic, readonly, strong) NSArray<IESEffectModel *> *childrenEffects;
@property (nonatomic, readonly, copy) NSString *parentEffectID;
@property (nonatomic, readonly, assign) IESEffectModelEffectSource source;
@property (nonatomic, readonly, copy) NSString *designerId;
@property (nonatomic, readonly, copy) NSString *schema;
@property (nonatomic, readonly, copy) NSArray<NSString *> *algorithmRequirements;
@property (nonatomic, readonly, copy) NSString *extra; // extra字段存放额外的信息，JSON内容的string.
@property (nonatomic, readonly, copy) NSArray<NSString *> *musicIDs; // 音乐id列表
@property (nonatomic, readonly, copy, nullable) NSArray<NSString *> *challengeIDs; // 绑定挑战id eg. ["123", "456"]
@property (nonatomic, readonly, assign) BOOL isCommerce; // 是否是商业化贴纸
@property (nonatomic, readonly, copy) NSString *iopId;
@property (nonatomic, readonly, assign) BOOL isIop;
@property (nonatomic, readonly, copy) NSString *designerEncryptedId; // 设计师加密id
@property (nonatomic, readonly, copy) NSString *sdkExtra;
@property (nonatomic, readonly, copy) NSString *adRawData;
@property (nonatomic, readonly, copy) NSString *resourceId;
@property (nonatomic, readonly, copy) NSArray<NSString *> *bindIDs;
@property (nonatomic, readonly, assign) long long ptime; // 特效发布时间
@property (nonatomic, copy) NSString *panelName; // Panel the sticker belongs to.
@property (nonatomic, assign) BOOL isChecked; // 是否处于选中状态（可能是用户选中，也可能是内置的，也可能是后台配置默认选中，可取消）
@property (nonatomic, assign) BOOL isBuildin; // 是否是内置，如果是内置，则用户不能取消勾选
@property (nonatomic, readonly, copy) NSDictionary *modelNames; // 模型名称

@property (nonatomic, copy) NSString *recId; // rec_id to track recommendation query history
@property (nonatomic, readonly, copy) NSString *hintFileURI; // 提示文件URI
@property (nonatomic, readonly, copy) NSArray<NSString *> *hintFileURLs; // 提示文件urlList
@property (nonatomic, readonly, assign) NSInteger hintFileFormat; // 提示文件格式(包括:文本、PNG、gif、lottie)

@property (nonatomic, assign) unsigned long long use_number;//特效使用人数, 需要和安卓保持一样的变量名

//以下为D业务推荐接口返回字段，不会通过loki下发
@property (nonatomic, copy) NSArray<NSString *> *videoPlayURLs;//特效演示视频的播放地址list
@property (nonatomic, copy) NSString *nickName;//特效演示视频nickname
@property (nonatomic, copy) NSString *avatarThumbURI;//特效演示视频作者图像uri
@property (nonatomic, copy) NSArray<NSString *> *avatarThumbURLs;//特效演示视频作者图像url_list

- (void)updateChildrenEffectsWithCollection:(NSArray<IESEffectModel *> *)collection;
- (void)updateChildrenEffectsWithCollectionDictionary:(NSDictionary<NSString *, IESEffectModel *> *)collectionDictionay;

// 替换一个model的types
- (void)updateTypes:(NSArray<NSString *> *)types;
- (void)updateSDKExtra:(NSString *)sdkExtra;

// 根据URLPrefix和fileDownloadURI，iconDownloadURI拼接生成fileDownloadURLs，iconDownloadURLs
- (void)setURLPrefix:(NSArray<NSString *> *)URLPrefix;

@end

@interface IESEffectModel (EffectDownloader)

// exist when this effect is downloaded
@property (nonatomic, readonly, copy) NSString *filePath;
@property (nonatomic, readonly, assign) BOOL downloaded;

- (BOOL)checkAlgorithmRelatedFieldsDecryptFailed;

@end

@interface IESEffectModel (BookMark)
- (BOOL)showRedDotWithTag:(NSString *)tag;
- (void)markAsReaded;
@end

NS_ASSUME_NONNULL_END

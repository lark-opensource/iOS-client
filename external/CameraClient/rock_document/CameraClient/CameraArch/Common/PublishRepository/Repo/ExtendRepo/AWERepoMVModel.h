//
//  AWERepoMVModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import <CreationKitArch/ACCRepoMVModel.h>
#import "ACCEditMVModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;

@interface ACCMVServerMaterialInfo : NSObject

@property (nonatomic, copy) NSString *nativeMaterialPath;
@property (nonatomic, copy) NSString *algorithmName;
@property (nonatomic, copy) NSString *algorithmJson;
@property (nonatomic, copy) NSString *resultMaterialPath;//该地址不在局限于图片，也可以是视频
@property (nonatomic, assign) VEMVAlgorithmResultInType algorithmResultType;

+ (NSArray *)mergeServerMaterialInfo:(NSArray<ACCMVServerMaterialInfo *> *)sourceArray;
+ (NSArray<NSString *> *)generateLocalAlgorithmMaterial:(NSArray<ACCMVServerMaterialInfo *> *)sourceArray;

@end

@class ACCMVAudioBeatTrackManager;

@interface AWERepoMVModel : ACCRepoMVModel <ACCRepositoryContextProtocol, ACCRepositoryTrackContextProtocol>

@property (nonatomic, assign) NSInteger mvTemplateCategoryID; // 影集模板id

@property (nonatomic, strong, nullable) ACCEditMVModel *mvModel;//IESMMMVModel MV 和 status的数据

@property (nonatomic, copy) NSArray<NSString*> *mvChallengeNameArray; // 影集支持多话题

@property (nonatomic, copy) NSString *mvID; // 影集ID，打点用

@property (nonatomic, strong) NSMutableArray<ACCMVServerMaterialInfo *> *serverMaterials;

// 影集MV卡点
@property (nonatomic, strong) ACCMVAudioBeatTrackManager *audioBeatTrackManager;

// only for draft
@property (nonatomic, copy, nullable) NSString *templateMaterialsString; // 为已选中的模板选中的素材路径，位于草稿箱中

// 一键成片入口，打点用
@property (nonatomic, copy, nullable) NSString *oneKeyMVEnterfrom;

@property (nonatomic, copy, nullable) NSString *previousPage;

@end

@interface AWEVideoPublishViewModel (AWERepoMV)
 
@property (nonatomic, strong, readonly) AWERepoMVModel *repoMV;
 
@end

NS_ASSUME_NONNULL_END

//
//  AWERepoCutSameModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/23.
//

#import <CreationKitArch/ACCRepoCutSameModel.h>
#import <VideoTemplate/LVTemplateDataManager.h>
#import <NLEPlatform/NLEModel+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEAssetModel;

@interface ACCMediaResource : NSObject

@property (nonatomic, strong) AWEAssetModel *assetInfo;
@property (nonatomic, strong) NSString *relativePath;

@end

@interface AWERepoCutSameModel : ACCRepoCutSameModel <NSCopying, ACCRepositoryContextProtocol>

@property (nonatomic, copy) NSArray<NSString *> *cutSameChallengeIDs;
@property (nonatomic, copy) NSArray<NSString *> *cutSameChallengeNames;

@property (nonatomic, strong) NSArray<ACCMediaResource *> *sourceMedia;
// 模板所在空间[字段定义：https://bytedance.feishu.cn/docs/doccnHbnIz2Kxnt9Xw3Kt9dxgBd]
@property (nonatomic, assign) NSInteger templateSource;
// cut same link optimization
@property (nonatomic, strong) NLEModel_OC *cutSameNLEModel;

@property (nonatomic, strong) NSArray<id<ACCMVTemplateModelProtocol>> *templatesArray;
@property (nonatomic, assign) NSUInteger currentSelectIndex;
@property (nonatomic, strong) NSArray<AWEAssetModel *> *currentTemplateAssets;
@property (nonatomic, strong) LVTemplateDataManager *dataManager;

@property (nonatomic, assign) BOOL isNLECutSame;

@property (nonatomic, assign) CGFloat cutsameOriginVoiceVolume;
@property (nonatomic,   copy) NSString *originSmartMVMusicID; // for smart mv track
@property (nonatomic,   copy) NSString *oneClickFilmingImprID; // for one click filming track

- (BOOL)isCutSame;
- (BOOL)canTransferToCutSame;
- (BOOL)isSmartFilming;
- (BOOL)isNewCutSameOrSmartFilming;
- (CGFloat)originRatio;
- (NSValue * __nullable)preferVideoSize;
- (NSDictionary *)smartVideoAdditonParamsForTrack;
- (NSDictionary *)smartVideoAdditionParamsForPublishTrack;

@end

@interface AWEVideoPublishViewModel (AWERepoCutSame)
 
@property (nonatomic, strong, readonly) AWERepoCutSameModel *repoCutSame;
 
@end

NS_ASSUME_NONNULL_END

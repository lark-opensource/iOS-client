//
//  ACCCutSameToEditManagerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by qiyang on 2021/1/28.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import "ACCMusicMVTemplateModelProtocol.h"
#import "AWEAssetModel.h"

NS_ASSUME_NONNULL_BEGIN

@class LVTemplateDataManager;
@class ACCMomentAIMomentModel;

@protocol ACCCutSameToEditManagerProtocol <NSObject>

// 影集剪同款: 输入模版、相册素材，初始化NLEModel并进入编辑页
- (void)startCutSameDataProcessWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                 materialAssets:(NSArray<AWEAssetModel *> *)selectedAssets
                                  templateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                                 progressHandle:(void(^)(CGFloat progress))progressHandle
                                     completion:(void(^)(NSError *error))completion;

// 一键mv: 输入musicMVTemplateModel，输出模版列表、初始化NLEModel并进入编辑页
- (void)startSmartMVDataProcessWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                           musicMVTemplateModel:(id<ACCMusicMVTemplateModelProtocol>)musicMVTemplate
                              smartMVCommonInfo:(NSDictionary *)smartMVCommonInfo
                                     completion:(void(^)(BOOL))completion;


- (NSArray<id<ACCMVTemplateModelProtocol>> *)transformMVTemplateModelFromJSON:(NSArray *)modelJSONArray
                                                                    extraJSON:(NSArray *)extraJSONArray;

@end

NS_ASSUME_NONNULL_END

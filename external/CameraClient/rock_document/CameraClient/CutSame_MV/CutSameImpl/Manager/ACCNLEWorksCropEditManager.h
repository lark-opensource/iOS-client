//
//  ACCNLEWorksCropEditManager.h
//  CameraClient-Pods-Aweme
//
//  Created by wanghongyu on 2021/2/28.
//

#import <Foundation/Foundation.h>
#import "ACCWorksCropEditView.h"
#import "ACCWorksPreviewVideoEditView.h"
#import "AWECutSameMaterialAssetModel.h"
#import <VideoTemplate/LVTemplateDataManager+Fetcher.h>
#import "ACCWorksPreviewViewControllerProtocol.h"
#import "ACCCutSameStyleCropEditManagerProtocol.h"
#import "ACCFragmentBridgeFragment.h"


NS_ASSUME_NONNULL_BEGIN


@class AWECutSameMaterialAssetModel;

typedef NS_ENUM(NSUInteger, ACCWorksCropEditManagerType) {
    ACCWorksCropEditManagerTypeCutSame = 0,
    ACCWorksCropEditManagerTypeMoment,
    ACCWorksCropEditManagerTypeSmartMV,
};

typedef void(^ACCWorksCropEditManagerSaveBlock)(AWECutSameMaterialAssetModel * _Nullable newMaterialAssetModel, BOOL isEdited);

@interface ACCNLEWorksCropEditManager : NSObject<ACCCutSameStyleCropEditManagerProtocol>


- (instancetype)initWithDataManager:(LVTemplateDataManager *)dataManager
                           fragment:(LVCutSameVideoMaterial *)fragment
                      fragmentModel:(nonnull id<ACCCutSameFragmentModelProtocol>)fragmentModel
                             curIdx:(NSInteger)curIdx
                           aligMode:(NSString *)alignMode
                          nleFolder:(nullable NSString *)nleFolder
                              toNLE:(nullable NLEModel_OC *)nleModel;

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, strong) ACCFragmentBridgeFragment *bridgeFragment;

@property (nonatomic, strong, readonly) LVCutSameVideoMaterial *fragment;

@property (nonatomic, strong, readonly) LVTemplateDataManager *dataManager;

@property (nonatomic, strong, readonly) id<ACCCutSameFragmentModelProtocol> fragmentModel;

@property (nonatomic, strong) ACCWorksCropEditView *editView;

@property (nonatomic, strong) ACCWorksPreviewVideoEditView *bottomView;

@property (nonatomic, copy  ) ACCWorksPreviewViewControllerChangeMaterialBlock changeMaterialAction;

@property (nonatomic, copy  ) ACCWorksCropEditManagerSaveBlock saveAction;

@property (nonatomic, copy  ) dispatch_block_t closeAction;

@property (nonatomic, assign) ACCWorksCropEditManagerType type;

@end

NS_ASSUME_NONNULL_END

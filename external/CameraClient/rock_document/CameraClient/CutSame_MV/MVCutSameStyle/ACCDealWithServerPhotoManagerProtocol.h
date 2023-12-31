//
//  ACCDealWIthServerManager.h
//  CameraClient
//
//  Created by xulei on 2020/6/3.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "AWECutSameMaterialAssetModel.h"

@class IESMMMVResource;
@class IESEffectModel;
@class VEMVAlgorithmResult;

@protocol ACCDealWithServerPhotoManagerProtocol <NSObject>

@property (nonatomic, strong) NSArray<IESMMMVResource *> *selectedResources;
@property (nonatomic, strong) IESEffectModel *templateEffectModel;
@property (nonatomic, strong) void (^enterVideoEditorBlock)(NSArray<VEMVAlgorithmResult *> *) ;
@property (nonatomic, strong) AWEVideoPublishViewModel *originUploadPublishModel;
@property (nonatomic, strong) void (^errorBlock)(void);

- (void)process;

@end

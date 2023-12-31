//
//  ACCDuetLayoutManager.h
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/7.
//

#import <Foundation/Foundation.h>

#import <TTVideoEditor/IESMMCamera.h>
#import <TTVideoEditor/IESMMRecoderProtocol.h>

#import "ACCDuetLayoutModel.h"
#import <CreationKitRTProtocol/ACCCameraService.h>

NS_ASSUME_NONNULL_BEGIN

@class IESMMCamera;
@class ACCDuetLayoutManager;

@protocol ACCDuetLayoutManagerDelegate <NSObject>

- (void)succeedDownloadFirstLayoutResource;
- (void)duetLayoutManager:(ACCDuetLayoutManager *)manager willApplyDuetLayoutModel:(ACCDuetLayoutModel *)model;
- (void)duetLayoutManager:(ACCDuetLayoutManager *)manager didApplyDuetLayout:(NSString *)duetLayout;
- (void)duetLayoutManager:(ACCDuetLayoutManager *)manager loadEffectsFinished:(BOOL)success;

@end

@interface ACCDuetLayoutManager : NSObject

@property (nonatomic, strong) NSArray <ACCDuetLayoutModel *> *duetLayoutModels;
@property (nonatomic, assign) BOOL needSwitchLayoutFirstTime;
@property (nonatomic, assign) BOOL hasErrorWhenFetchingEffects;
@property (nonatomic, assign) NSInteger firstTimeIndex;
@property (nonatomic, copy) NSString *firstDuetLayout;
@property (nonatomic, strong) id<ACCCameraService> cameraService;

- (instancetype)initWithDelegate:(id<ACCDuetLayoutManagerDelegate>)delegate;

- (void)applyDefaultDuetLayouts;
- (BOOL)applyFirstDuetLayoutsIfEnable;
- (void)downloadDuetLayoutResources;
- (void)applyDuetLayoutWithIndex:(NSInteger)index;
- (void)toggleDuetLayoutWithIndex:(NSInteger)index;
- (NSInteger)indexFromDuetLayout:(NSString *)duetLayout;

@end

NS_ASSUME_NONNULL_END

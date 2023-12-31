//
//  ACCRecordContainerMode.h
//  CameraClient-Pods-Aweme
//
//  Created by Kevin Chen on 2020/12/21.
//

#import <CreationKitArch/ACCRecordMode.h>
#import <CreationKitInfra/ACCModuleService.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordContainerMode : ACCRecordMode

@property (nonatomic, copy) NSArray<ACCRecordMode *> *submodes;
@property (nonatomic, strong) NSArray<NSString *> *submodeTitles;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger defaultIndex;
@property (nonatomic, assign, readonly) NSInteger realModeId;

- (void)configWithModesArray:(NSArray<ACCRecordMode *> *)submodes titles:(NSArray<NSString *> *)titles landingMode:(ACCRecordModeIdentifier)modeID defaultModeIndex:(NSInteger)defaultModeIndex;

- (void)setCurrentMode:(ACCRecordMode *)currentMode;

@end

NS_ASSUME_NONNULL_END

//
//  ACCRecordSwitchModeService.h
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/11/16.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCModuleService.h>
#import "ACCRecordMode.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecordSwitchModeServiceSubscriber <NSObject>

@optional

- (void)switchModeServiceWillChangeToMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode;
- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode;
- (void)modeArrayDidChanged;
- (void)tabConfigDidUpdatedWithModeId:(NSInteger)modeId;
- (void)didUpdatedSelectedIndex:(NSInteger)index isInitial:(BOOL)initial;
- (void)lengthModeDidChanged;

- (BOOL)shouldCalledLast;

@end

@protocol ACCRecordSwitchModeService <NSObject>

@property (nonatomic, strong, readonly) NSMutableArray <ACCRecordMode *> *modeArray;

@property (nonatomic, strong, readonly) ACCRecordMode *currentRecordMode;

@property (nonatomic, weak, readonly) ACCRecordMode *changingToMode;

@property (nonatomic, copy, nullable, readonly) NSArray<AWESwitchModeSingleTabConfig *> *tabConfigArray;

- (void)addMode:(ACCRecordMode *)mode;
- (void)removeMode:(ACCRecordMode *)mode;

// MT: Allow creators to change to longer duration after recording
- (void)updateModesStartWithLengthMode:(ACCRecordLengthMode)lengthMode;
- (void)recoverOriginalModes;

- (ACCRecordMode *)initialRecordMode;

- (void)switchMode:(ACCRecordMode *)mode;

- (NSInteger)siblingsCountForRecordModeId:(NSInteger)targetMode;

- (NSInteger)getIndexForRecordModeId:(NSInteger)recordModeId;

- (ACCRecordMode *)getRecordModeForIndex:(NSInteger)index;

- (BOOL)containsModeWithId:(NSInteger)modeId;

- (void)updateModeSelection:(BOOL)initial;

- (void)updateTabConfigForModeId:(NSInteger)modeId Block:(void (^)(AWESwitchModeSingleTabConfig * _Nonnull))updateBlock;

- (void)addSubscriber:(id<ACCRecordSwitchModeServiceSubscriber>)subscriber;

- (BOOL)isInSegmentMode;

- (BOOL)isInSegmentMode:(ACCRecordMode *)mode;

- (BOOL)isVideoCaptureMode;

- (void)switchToLengthMode:(ACCRecordLengthMode)lengthMode;

@end

NS_ASSUME_NONNULL_END

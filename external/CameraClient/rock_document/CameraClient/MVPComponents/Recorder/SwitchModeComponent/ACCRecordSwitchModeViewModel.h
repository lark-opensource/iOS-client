//
//  ACCRecordSwitchModeViewModel.h
//  CameraClient
//
//  Created by Me55a on 2020/2/10.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCSwitchModeContainerView.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>

@class ACCRecordMode;
NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordSwitchModeViewModel : ACCRecorderViewModel <ACCSwitchModeContainerViewDelegate, ACCSwitchModeContainerViewDataSource>

- (void)changeCurrentLengthMode:(ACCRecordMode *)recordMode;

@end

NS_ASSUME_NONNULL_END

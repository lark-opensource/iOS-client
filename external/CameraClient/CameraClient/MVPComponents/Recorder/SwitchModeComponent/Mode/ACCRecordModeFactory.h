//
//  ACCRecordModeFactory.h
//  CameraClient
//
//  Created by yangying on 2020/11/26.
//

#ifndef ACCRecordModeFactory_h
#define ACCRecordModeFactory_h

#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>

@class ACCRecordMode;

@protocol ACCRecordModeFactory <NSObject>

- (NSMutableArray <ACCRecordMode *>*)displayModesArray;

- (ACCRecordMode *)modeWithIdentifier:(NSInteger)identifier;

@optional
- (ACCRecordMode *)modeWithLength:(ACCRecordLengthMode)length;

- (ACCRecordMode *)modeWithButtonType:(AWEVideoRecordButtonType)buttonType;

@end

#endif /* ACCRecordModeFactory_h */

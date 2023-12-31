//
//  ACCRecorderViewModel.h
//  CameraClient
//
//  Created by DING Leo on 2020/2/11.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCViewModel.h>
#import <IESInject/IESInject.h>

@class ACCRecordViewControllerInputData, AWEVideoPublishViewModel;
NS_ASSUME_NONNULL_BEGIN

@interface ACCRecorderViewModel : NSObject <ACCViewModel>

@property (nonatomic, strong) ACCRecordViewControllerInputData *inputData;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

@end

NS_ASSUME_NONNULL_END

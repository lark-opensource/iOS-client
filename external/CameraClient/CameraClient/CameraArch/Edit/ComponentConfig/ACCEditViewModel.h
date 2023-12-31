//
//  ACCEditViewModel.h
//  CameraClient
//
//  Created by liuqing on 2020/2/21.
//

#import <Foundation/Foundation.h>
#import "ACCEditViewControllerInputData.h"
#import <CreativeKit/ACCViewModel.h>
#import <IESInject/IESInject.h>

NS_ASSUME_NONNULL_BEGIN


@class IESEffectModel, AWEVideoPublishViewModel;
@interface ACCEditViewModel : NSObject <ACCViewModel>

@property (nonatomic, strong) ACCEditViewControllerInputData *inputData;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

@end

NS_ASSUME_NONNULL_END

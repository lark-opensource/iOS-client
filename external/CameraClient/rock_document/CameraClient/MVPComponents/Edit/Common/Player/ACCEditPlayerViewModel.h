//
//  ACCEditPlayerViewModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/7/8.
//

#import <Foundation/Foundation.h>
#import "ACCEditViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditServiceProtocol;
@interface ACCEditPlayerViewModel : ACCEditViewModel

@property (nonatomic, strong, readonly) RACBehaviorSubject *playerShouldPlaySignal;
@property (nonatomic, strong) NSNumber *shouldPlay; // boolValue

@end

NS_ASSUME_NONNULL_END

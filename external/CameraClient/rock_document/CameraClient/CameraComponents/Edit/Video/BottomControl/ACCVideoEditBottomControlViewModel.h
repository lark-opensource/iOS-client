//
//  ACCVideoEditBottomControlViewModel.h
//  CameraClient-Pods-AwemeCore
//
//  Created by ZZZ on 2021/9/27.
//

#import "ACCEditViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCVideoEditBottomControlService.h"
#import "ACCVideoEditBottomControlLayout.h"

@interface ACCVideoEditBottomControlViewModel : ACCEditViewModel <ACCVideoEditBottomControlService>

@property (nonatomic, strong, nullable, readonly) RACSignal *shouldUpdatePanelSignal;

@property (nonatomic, copy, nullable, readonly) NSString *publishButtonTitle;
@property (nonatomic, assign, readonly) BOOL showsPublishButton;
@property (nonatomic, assign, readonly) BOOL showsNextButton;

@property (nonatomic, strong, nullable) id <ACCVideoEditBottomControlLayout> layout;

- (void)notifyDidTapType:(ACCVideoEditFlowBottomItemType)type;

- (NSArray<NSNumber *> *)allItemTypes;

@end

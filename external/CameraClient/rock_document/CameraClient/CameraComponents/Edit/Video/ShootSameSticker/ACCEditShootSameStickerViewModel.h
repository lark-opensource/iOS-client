//
//  ACCEditShootSameStickerViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/23.
//

#import "ACCEditViewModel.h"

#import "ACCStickerServiceProtocol.h"
#import "ACCShootSameStickerViewModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditShootSameStickerViewModel : ACCEditViewModel <ACCShootSameStickerViewModelProtocol>

@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;

@end

NS_ASSUME_NONNULL_END

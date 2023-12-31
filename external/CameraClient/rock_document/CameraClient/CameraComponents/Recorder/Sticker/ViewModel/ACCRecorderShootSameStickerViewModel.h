//
//  ACCRecorderShootSameStickerViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import <Foundation/Foundation.h>

#import <CreationKitArch/ACCRecorderViewModel.h>
#import "ACCRecorderStickerServiceProtocol.h"
#import "ACCShootSameStickerViewModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecorderShootSameStickerViewModel : ACCRecorderViewModel <ACCShootSameStickerViewModelProtocol>

@property (nonatomic, weak) id<ACCRecorderStickerServiceProtocol> stickerService;

@end

NS_ASSUME_NONNULL_END

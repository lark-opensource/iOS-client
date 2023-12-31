//
//  ACCLiveStickerServiceImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/1/29.
//

#import <Foundation/Foundation.h>
#import "ACCLiveStickerServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCLiveStickerServiceImpl : NSObject<ACCLiveStickerServiceProtocol>

@property (nonatomic, strong) RACSubject<NSNumber *> *toggleEditingViewSubject;

@end

NS_ASSUME_NONNULL_END

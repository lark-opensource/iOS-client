//
//  ACCRecordAuthService.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2021/1/11.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecordAuthService <NSObject>

@property (nonatomic, strong, readonly) RACSignal *confirmAllowUseCameraSignal;
@property (nonatomic, strong, readonly) RACSignal <NSNumber *> *passCheckAuthSignal;

@end

NS_ASSUME_NONNULL_END

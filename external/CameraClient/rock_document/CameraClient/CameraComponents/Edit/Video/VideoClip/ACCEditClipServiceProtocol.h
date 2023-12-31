//
//  ACCEditClipServiceProtocol.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by Chen Long on 2020/12/31.
//

#import <CreationKitInfra/ACCRACWrapper.h>

#ifndef ACCEditClipServiceProtocol_h
#define ACCEditClipServiceProtocol_h

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditClipServiceSubscriber <NSObject>

- (void)willRemoveAllEdits;
- (void)didRemoveAllEdits;

@end

@protocol ACCEditClipServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *removeAllEditsSignal;
@property (nonatomic, strong, readonly) RACSignal *willRemoveAllEditsSignal;
@property (nonatomic, strong, readonly) RACSignal *didRemoveAllEditsSignal;
@property (nonatomic, strong, readonly) RACSignal *didFinishClipEditSignal;

- (void)addSubscriber:(id<ACCEditClipServiceSubscriber>)subscriber;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCEditClipServiceProtocol_h */

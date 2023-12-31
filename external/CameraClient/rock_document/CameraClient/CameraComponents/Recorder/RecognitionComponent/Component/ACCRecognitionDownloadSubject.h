//
//  ACCRecognitionDownloadSubject.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/7/7.
//

#import <ReactiveObjC/ReactiveObjC.h>

@class IESEffectModel;
NS_ASSUME_NONNULL_BEGIN

@interface ACCRecognitionDownloadSubject : NSObject

- (nullable RACSignal *)progressSignalForEffect:(IESEffectModel *)effect;
- (nullable RACSignal *)resultSignalForEffect:(IESEffectModel *)effect;

- (void)downloadEffect:(IESEffectModel *)effect;

- (void)willRelease;

@end

NS_ASSUME_NONNULL_END

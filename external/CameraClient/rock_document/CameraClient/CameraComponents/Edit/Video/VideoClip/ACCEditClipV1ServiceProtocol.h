//
//  ACCEditClipV1ServiceProtocol.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by Chen Long on 2020/12/31.
//

#import <Foundation/Foundation.h>

#ifndef ACCEditClipV1ServiceProtocol_h
#define ACCEditClipV1ServiceProtocol_h

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditClipV1ServiceProtocol <NSObject>

@property (nonatomic, assign, readonly) BOOL isSingleAsset;

@property (nonatomic, assign, readonly) BOOL isCliping;

@property (nonatomic, strong, readonly) RACSignal *removeAllEditsSignal;

@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *didFinishClipEditSignal;

@property (nonatomic, strong, readonly) RACSignal *finishClipCheckMusicSignal;

@property (nonatomic, strong, readonly) RACSignal *videoClipClickedSignal;

@property (nonatomic, strong, readonly) RACSignal *refreshMusicVolumeAfterAiClipSignal;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCEditClipV1ServiceProtocol_h */

//
//  ACCEffectTrackViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/12/14.
//

#import <CreationKitArch/ACCRecorderViewModel.h>

@class AWEVideoFragmentInfo;

typedef NS_OPTIONS(NSUInteger, ACCTrackMessageType) {
    ACCTrackMessageTypeRecord   = 1L << 0, // 拍摄页上报，收到 effect 消息, 马上上报
    ACCTrackMessageTypeEdit     = 1L << 1, // 开拍后收到的埋点消息，需要进入编辑页后进行上报
    ACCTrackMessageTypePublish  = 1L << 2, // 开拍后收到的埋点消息，需要发布成功后进行上报
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCEffectTrackViewModel : ACCRecorderViewModel

@property (nonatomic, copy) NSString*(^currentStickerHandler)(void);


- (void)trackRecordWithEvent:(NSString *)event params:(NSDictionary *)params;

- (void)updateEffectTrackModelWithParams:(NSDictionary *)params type:(ACCTrackMessageType)type;

- (void)addFragment:(AWEVideoFragmentInfo *)fragmentInfo;

- (void)clearTrackParamsCache;

@end

NS_ASSUME_NONNULL_END

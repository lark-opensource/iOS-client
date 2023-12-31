//Copyright © 2021 Bytedance. All rights reserved.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CreationKitArch/ACCStudioDefines.h>
#import <CreationKitArch/AWETimeRange.h>
#import <CreationKitArch/AWEVideoStickerSavePhotoInfo.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCVideoFragmentInfoProtocol <NSObject>

@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;
@property (nonatomic, assign) BOOL beautify;
@property (nonatomic, assign) BOOL beautifyUsed;
@property (nonatomic, assign) BOOL composerBeautifyUsed;
@property (nonatomic, copy) NSString *composerBeautifyInfo;
@property (nonatomic, copy) NSString *composerBeautifyEffectInfo;
@property (nonatomic, copy) NSString *colorFilterId;
@property (nonatomic, copy) NSString *colorFilterName;
@property (nonatomic, copy) NSString *recordMode;

@property (nonatomic, copy) NSString *background;
@property (nonatomic, copy) NSString *stickerId;
@property (nonatomic, strong) AWEVideoStickerSavePhotoInfo *stickerSavePhotoInfo;

@property (nonatomic, copy) NSString *propRecId;
@property (nonatomic, copy) NSString *stickerGradeKey;
@property (nonatomic, strong) NSArray<NSString *> *propBindMusicIdArray;
@property (nonatomic, assign) double speed;
@property (nonatomic, copy) NSString *musicEffect;
@property (nonatomic, assign) BOOL useStabilization;
@property (nonatomic, assign) BOOL watermark;
@property (nonatomic, assign) BOOL isReshoot;

@property (nonatomic, assign) float smooth;
@property (nonatomic, assign) float reshape;
@property (nonatomic, assign) float shape;
@property (nonatomic, assign) float eye;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, assign) float recordDuration;
@property (nonatomic, strong) NSIndexPath *propIndexPath;
@property (nonatomic, copy) NSString *propSelectedFrom;

@property (nonatomic, copy, nullable) NSArray <NSString *> *arTextArray;
@property (nonatomic, copy, nullable) NSArray <NSString *> *stickerTextArray;


@property (nonatomic, strong, nullable) NSMutableArray *originalFrames;
@property (nonatomic, copy) NSArray <NSString *> *originalFramesArray;

@property (nonatomic, strong) NSURL *stickerVideoAssetURL;
@property (nonatomic, assign) CGFloat stickerBGPlayedPercent;

@property (nonatomic, copy) NSString *backgroundID;
@property (nonatomic, copy) NSString *backgroundType;

@property (nonatomic, assign) AWEDelayRecordMode delayRecordModeType;
@property (nonatomic, copy) NSString *pic2VideoSource;
@property (nonatomic, strong, nullable) AWETimeRange *clipRange;

@property (nonatomic, assign) NSInteger figureAppearanceDurationInMS; //duet layout

- (void)deleteStickerSavePhotos:(NSString *)taskId;

@end

NS_ASSUME_NONNULL_END

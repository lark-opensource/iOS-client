//
//  ACCVideoConfigProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/21.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/HTSFilterDefine.h>
#import "AWEVideoPublishViewModelDefine.h"
#import "ACCAwemeModelProtocol.h"

@protocol ACCVideoConfigProtocol <NSObject>

// beauty && filter
@property (nonatomic, assign, readonly) HTSBeautifyType beautifyType;

@property (nonatomic, assign, readonly) double longVideoDurationLowerLimit;

@property (nonatomic, assign, readonly) NSInteger videoSelectableMinSeconds;
@property (nonatomic, assign, readonly) NSInteger videoSelectableMaxSeconds;

@property (nonatomic, assign, readonly) CGFloat minVideoRatio;
@property (nonatomic, assign, readonly) CGFloat maxVideoRatio;

@property (nonatomic, assign, readonly) NSInteger videoResolution;

@optional
@property (nonatomic, assign, readonly) NSInteger faceDetectInterval;

@property (nonatomic, assign, readonly) NSInteger videoMinSeconds;
@property (nonatomic, assign, readonly) NSInteger videoMaxSeconds;

@property (nonatomic, assign, readonly) NSInteger duetVideoMinSeconds;
@property (nonatomic, assign, readonly) NSInteger duetVideoMaxSeconds;

@property (nonatomic, assign, readonly) NSInteger threeMinVideoMaxSeconds;
@property (nonatomic, assign, readonly) NSInteger longVideoMaxSeconds;
@property (nonatomic, assign, readonly) NSInteger standardVideoMaxSeconds;

@property (nonatomic, assign, readonly) NSInteger videoUploadMaxSeconds;
@property (nonatomic, assign, readonly) NSInteger videoFromLvUploadMaxSeconds;
@property (nonatomic, assign, readonly) NSInteger musicMaxSeconds;
@property (nonatomic, assign, readonly) NSInteger clipVideoInitialMaxSeconds;
@property (nonatomic, assign, readonly) NSInteger clipVideoFromLvInitialMaxSeconds;

@property (nonatomic, assign, readonly) BOOL isLimitInitialMaxSeconds;
@property (nonatomic, assign, readonly) BOOL isReshoot;

@property (nonatomic, assign, readonly) NSInteger minAssetsSelectionCount;
@property (nonatomic, assign, readonly) NSInteger maxAssetsSelectionCount;

- (ACCRecordLengthMode)currentVideoLenthMode;

- (NSInteger)currentVideoMaxSeconds;

- (void)updateCurrentVideoLenthMode:(ACCRecordLengthMode)videoLenthMode;

- (BOOL)enableUploadClientBOE;

- (BOOL)enablePhotoHashTag;

- (BOOL)canOpenSoundPageForLongVideo;

// Does the bottom toolbar display title
- (BOOL)showTitleInVideoCameraBottomView;

- (NSInteger)publishMaxTitleLength;

- (BOOL)allowUploadLongVideo;

- (BOOL)needIsLongVideoParameter;

- (BOOL)limitMusicAccordingLongVideo;

- (BOOL)isLongVideoCanOpenSoundPage;

- (NSInteger)videoMaxSecondsWithMusic:(BOOL)hasMusic;

- (NSInteger)currentVideoMaxSecondsWithMusic:(BOOL)hasMusic;

- (BOOL)allowUploadSinglePhoto;

@end

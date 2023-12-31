//
//  ACCSelectMusicStudioParamsProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/9/8.
//  抖音选择音乐页面需要传的参数协议

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
@protocol ACCMusicModelProtocol;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCMusicEnterScenceType);

@protocol ACCSelectMusicStudioParamsProtocol <NSObject>
@property (nonatomic, assign) BOOL shouldHideCellMoreButton;
@property (nonatomic, assign) BOOL needDisableDeselectMusic;// photo to video need to disable music deselect
@property (nonatomic, assign) BOOL shouldHideCancelButton;
@property (nonatomic, assign) BOOL isFixDurationMode; // the total length is fixed, such as using multi seg prop
@property (nonatomic, assign) BOOL shouldHideSelectedMusicViewClipActionBtn; //例如图集需要隐藏裁剪操作
@property (nonatomic, assign) BOOL shouldHideSelectedMusicViewDeleteActionBtn; //例如图集不支持取消配乐时，需要隐藏删除操作
@property (nonatomic, strong) id<ACCMusicModelProtocol> sameStickerMusic; //同款道具音乐
@property (nonatomic, strong) id<ACCMusicModelProtocol> mvMusic;//mv影集音乐
@property (nonatomic, strong) id<ACCMusicModelProtocol> uploadRecommendMusic; // recommend for ai clip or photo video
@property (nonatomic, strong) id<ACCMusicModelProtocol> selectedMusic;//普通视频音乐
@property (nonatomic,   copy) NSString *previousPage;
@property (nonatomic, strong) NSArray *propBindMusicIdArray;
@property (nonatomic,   copy) NSString *propId;

@property (nonatomic, assign) ACCMusicEnterScenceType sceneType;
@property (nonatomic, assign) BOOL allowUsingVideoDurationAsMaxMusicDuration;
@property (nonatomic, assign) BOOL useSuggestClipRange;
@property (nonatomic, assign) BOOL enableMusicLoop;
@property (nonatomic, assign) HTSAudioRange audioRange;
@property (nonatomic, assign) CGFloat exsitingVideoDuration;
@property (nonatomic, copy, nullable) BOOL (^enableClipBlock)(id<ACCMusicModelProtocol>);
@property (nonatomic, copy, nullable) void (^didClipWithRange)(HTSAudioRange range, NSString *musicEditedFrom, BOOL enableMusicLoop, NSInteger repeatCount);
@property (nonatomic, copy, nullable) void (^didSuggestClipRangeChange)(BOOL selected);
@property (nonatomic, copy, nullable) void (^setForbidSimultaneousScrollViewPanGesture)(BOOL forbid);
@property (nonatomic, copy) NSDictionary *clipTrackInfo;
@property (nonatomic, assign) CGFloat fixDuration;

@property (nonatomic, assign) BOOL shouldAccommodateVideoDurationToMusicDuration; // 视频时长是否需要根据音乐时长来自适应
@property (nonatomic, assign) NSTimeInterval maximumMusicDurationToAccommodate; // 根据音乐来自适应的最大视频时长

@end



NS_ASSUME_NONNULL_END

//
//  ACCSelectMusicProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/9.
//  打开音乐选择页面

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CreationKitInfra/ACCCommonDefine.h>
#import <CreationKitArch/ACCRecodInputDataProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitInfra/ACCModuleService.h>
#import <CreationKitArch/ACCRecordMode.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;

typedef NS_ENUM(NSInteger, ACCMusicEnterScenceType) {
    ACCMusicEnterScenceTypeUnknow = 0,
    ACCMusicEnterScenceTypeRecorder,//录制页音乐选择页入口
    ACCMusicEnterScenceTypeAIClip,//老AI卡点的选择页入口
    ACCMusicEnterScenceTypeEditor,//编辑页
    ACCMusicEnterScenceTypeLyric,//歌词贴纸的选择页
};

typedef NS_ENUM(NSUInteger, ACCSelectMusicType) {
    //可切换的样式
    ACCSelectMusicTypeSwitchDefalut,//上传，选择音乐，开拍
    ACCSelectMusicTypeSwitchChallengeMusic,//同AWESelectMusicVCTypeSwitchDefalut，会显示出挑战音乐列表
    //只显示标题的样式
    ACCSelectMusicTypeTitleSelect,//@"选择音乐"
    ACCSelectMusicTypeTitleChange,//@"更改音乐"
    ACCSelectMusicTypeTitleChallengeMusic,//如果挑战带音乐并且从直接开拍方案进入,只需要显示标题.AWESelectMusicVCTypeSwitchChallengeMusic用于原始方案
};

typedef void (^ACCASSSelectMusicCompletion)(id<ACCMusicModelProtocol> _Nullable music, NSError * _Nullable error);
typedef void (^ACCASSCancelMusicCompletion)(id<ACCMusicModelProtocol> _Nullable music);
typedef void (^ACCASSWillCloseBlock)(void);
@protocol ACCSelectMusicComponetCommonProtocol <NSObject>
@property (nonatomic, strong) id<ACCChallengeModelProtocol> challenge;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol>selectedMusic; // 当前选中的音乐（不包括mv音乐）
@property (nonatomic, copy) ACCASSSelectMusicCompletion pickCompletion;
@property (nonatomic, copy) ACCASSCancelMusicCompletion cancelMusicCompletion;
@property (nonatomic, copy) ACCASSWillCloseBlock willCloseBlock;
@property (nonatomic, assign) ACCServerRecordMode recordServerMode;
@property (nonatomic, assign) ACCRecordModeIdentifier recordMode;
@property (nonatomic, assign) NSTimeInterval videoDuration;
@property (nonatomic, assign) BOOL disableCutMusic;
@end

//ACCSelectMusicInputData的另一种形态
@protocol ACCSelectMusicInputDataProtocol <NSObject>
@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic,   copy) NSString *ugcPathRefer;
@property (nonatomic, strong) id<ACCMusicModelProtocol>sameStickerMusic;
@property (nonatomic, strong) id<ACCChallengeModelProtocol> challenge;

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
@property (nonatomic, assign) BOOL disableCutMusic;
@end



@protocol ACCSelectMusicProtocol <NSObject>

- (nonnull UIViewController<ACCSelectMusicComponetCommonProtocol> *)selectMusicPageWithInputData:(id<ACCSelectMusicInputDataProtocol> _Nullable)inputData
                                                                                      pick:(ACCASSSelectMusicCompletion _Nullable)pickCompletion
                                                                                    cancel:(ACCASSCancelMusicCompletion _Nullable)cancelMusicCompletion
                                                                                     close:(ACCASSWillCloseBlock _Nullable)willCloseBlock;

- (nonnull UIViewController<ACCSelectMusicComponetCommonProtocol> *)selectMusicPageWithInputData:(id<ACCSelectMusicInputDataProtocol> _Nullable)inputData
                                                                                            pick:(ACCASSSelectMusicCompletion _Nullable)pickCompletion
                                                                                          cancel:(ACCASSCancelMusicCompletion _Nullable)cancelMusicCompletion;
@end


NS_ASSUME_NONNULL_END

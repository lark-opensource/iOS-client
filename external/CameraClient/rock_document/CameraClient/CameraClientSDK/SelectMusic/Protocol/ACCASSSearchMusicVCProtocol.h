//
//  ACCASSSearchMusicVCProtocol.h
//  AWEStudio-Pods-Aweme
//
//  Created by Zhihao Zhang on 2021/2/22.
//

#import <Foundation/Foundation.h>

#import "HTSVideoAudioSupplier.h"
#import "ACCSelectMusicViewControllerProtocol.h"
#import "ACCMusicCommonSearchBarProtocol.h"
#import <CreationKitInfra/ACCModuleService.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@protocol ACCASSSearchMusicVCProtocol
<
HTSVideoAudioSupplier,
ACCViewControllerEmptyPageHelperProtocol
>

@property (nonatomic, copy) void(^solveCloseGesture)(UIPanGestureRecognizer *panGesture);//浮层关闭手势冲突解决
@property (nonatomic, copy) void(^didSelectHistoryQuery)(NSString *query);
@property (nonatomic, copy) void(^dismissKeyboard)(void);
@property (nonatomic, copy) void(^didSelectSugQuery)(NSString *query);
@property (nonatomic, copy) void(^didSelectComplementQuery)(NSString *query);
@property (nonatomic, copy) void(^updatePublishModelCategoryIdBlock)(NSString *);
@property (nonatomic, copy) NSString *previousPage;

@property (nonatomic, copy) NSString *creationId;
@property (nonatomic, assign) CGFloat shootDuration;
@property (nonatomic, assign) ACCRecordModeIdentifier recordMode;
@property (nonatomic, strong) AWEVideoPublishViewModel *repository;

@property (nonatomic, assign) BOOL shouldHideCellMoreButton;
@property (nonatomic, assign) BOOL disableCutMusic;

@property (nonatomic, weak) id<ACCMusicCommonSearchBarProtocol> searchBar;


- (void)searchWithKeyword:(NSString *)keyword enterFrom:(NSString *)enterFrom;
- (void)searchBeginEditing;
- (void)searchEndEditing;
- (void)textFieldClickReturn:(NSString *)query;

- (void)clear;
- (void)enterSearch;
- (void)changeSearchWord:(NSString *)keyword;
- (void)pausePlayer;

// 16.3.0 lynx音乐搜索结果调起剪辑面板上报埋点
- (void)lynxMusicSearchClipCanceled;
- (void)lynxMusicSearchClipConfirmed;

@end


@protocol ACCASSSearchMusicVCBuilderProtocol

/**
 * @brief 创建音乐搜索页
 */
- (UIViewController<ACCASSSearchMusicVCProtocol> *)createSearchMusicVC;



@end


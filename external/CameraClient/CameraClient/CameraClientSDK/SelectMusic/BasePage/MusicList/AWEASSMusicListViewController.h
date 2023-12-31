//
//  AWEASSMusicListViewController.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/11.
//  Copyright © 2018年 bytedance. All rights reserved.
//

@class AWEMusicCollectionData;

#import <UIKit/UIKit.h>
#import "HTSVideoAudioSupplier.h"
#import "ACCRefreshableViewControllerProtocol.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

typedef NS_ENUM(NSUInteger, AWEASSMusicListType) {
    AWEASSMusicListTypeUnknonwn,
    AWEASSMusicListTypeCategory,
    AWEASSMusicListTypeSearch,
    AWEASSMusicListTypeMusicSticker,
    AWEASSMusicListTypeKaraoke,
};

NS_ASSUME_NONNULL_BEGIN

@protocol AWEASSMusicListHeaderDataSource <NSObject>

@optional

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;

@end

@interface AWEASSMusicListViewController : UIViewController<HTSVideoAudioSupplier, ACCRefreshableViewControllerProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, strong) NSArray<AWEMusicCollectionData *> *dataList;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak) id<AWEASSMusicListHeaderDataSource> headerDataSource;
@property (nonatomic, assign) BOOL isDarkMode;
@property (nonatomic, assign) BOOL toShowNoLyricStyle;
@property (nonatomic, assign) BOOL isCommerce;
@property (nonatomic, assign) BOOL disableCutMusic;

@property (nonatomic, copy) void(^solveCloseGesture)(UIPanGestureRecognizer *panGesture);//浮层关闭手势冲突解决
@property (nonatomic, copy) void(^didSelectItem)(NSIndexPath *indexPath, AWEMusicCollectionData *data);
@property (nonatomic, copy) void(^didEndDragList)(UIScrollView *scrollView);
@property (nonatomic, copy) void(^didScrollBlock)(UIScrollView *scrollView);

// Tracking
@property (nonatomic, assign) AWEASSMusicListType listType;
@property (nonatomic, copy) NSString *enterMethod;
@property (nonatomic, copy) NSString *enterFrom;
@property (nonatomic, copy) NSString *categoryName;
@property (nonatomic, copy) NSString *categoryId;
@property (nonatomic, copy) NSString *previousPage;
@property (nonatomic, copy) NSString *keyword;
@property (nonatomic, copy) NSDictionary *logPb; // log related
@property (nonatomic, copy) NSString *creationId;
@property (nonatomic, copy) NSString *shootWay;
@property (nonatomic, assign) BOOL showRank;
@property (nonatomic, assign) BOOL showLyricLabel;
@property (nonatomic, assign) BOOL shouldHideCellMoreButton;
@property (nonatomic, assign) BOOL isSearchMusic;
@property (nonatomic, copy) void(^updatePublishModelCategoryIdBlock)(NSString * _Nullable);

- (void)pause;
- (void)clearContentOffset;

// 16.3.0 lynx音乐搜索结果调起剪辑面板上报埋点
- (void)lynxMusicSearchClipCanceled;
- (void)LynxMusicSearchClipConfirmed;

- (void)setDataListandPartialUpdateRows:(NSArray<AWEMusicCollectionData *> *)dataList;
@end

NS_ASSUME_NONNULL_END

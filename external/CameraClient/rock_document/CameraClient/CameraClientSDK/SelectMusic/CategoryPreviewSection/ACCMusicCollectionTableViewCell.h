//
//  ACCMusicCollectionTableViewCell.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/8.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "HTSVideoAudioSupplier.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>

#import <CameraClient/ACCPropRecommendMusicProtocol.h>
#import <CreationKitInfra/ACCModuleService.h>

@class AWEMusicCollectionData;
@class ACCMusicCollectionTableViewCell;

typedef void (^AWEMusicCollectionSelectBlock)(ACCMusicCollectionTableViewCell * _Nonnull cell, NSInteger row, id<ACCMusicModelProtocol> _Nonnull music);
typedef void (^AWEMusicCollectionConfirmAudioBlock)(id<ACCMusicModelProtocol> _Nullable audio, NSError * _Nullable error, NSString * _Nonnull categoryId, NSString * _Nonnull categoryName, NSInteger row);
typedef void (^AWEMusicCollectionMoreButtonClickBlock)(id<ACCMusicModelProtocol> _Nonnull music, NSString * _Nonnull categoryId, NSString * _Nonnull categoryName);
typedef void (^AWEMusicCollectionFavAudioBlock)(id<ACCMusicModelProtocol> _Nullable audio, NSString * _Nonnull categoryId, NSString * _Nonnull categoryName, NSInteger row);

NS_ASSUME_NONNULL_BEGIN

@interface ACCMusicCollectionTableViewCell : UITableViewCell<HTSVideoAudioSupplier>

@property (nonatomic, strong) UICollectionView *musicCollectionView;
@property (nonatomic, copy) AWEMusicCollectionSelectBlock selectMusicBlock;
@property (nonatomic, copy) AWEMusicCollectionConfirmAudioBlock confirmAudioBlock;
@property (nonatomic, copy) AWEMusicCollectionMoreButtonClickBlock moreButtonClicked;
@property (nonatomic, copy) AWEMusicCollectionFavAudioBlock favMusicBlock;
@property (nonatomic, copy) void (^tapWhileLoadingBlock)(void);
@property (nonatomic, assign) BOOL showMore;
@property (nonatomic, assign) BOOL showClipButton;
@property (nonatomic, assign) BOOL disableCutMusic;
@property (nonatomic, copy) NSString *previousPage;
@property (nonatomic, assign, readonly) CGFloat initialContentOffsetX;
@property (nonatomic, assign) BOOL isCommerce;
@property (nonatomic, assign) ACCServerRecordMode recordMode;
@property (nonatomic, assign) NSTimeInterval videoDuration;

- (void)configWithMusicCollectionData:(AWEMusicCollectionData *)data showTopLine:(BOOL)showTopLine;

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus forRow:(NSInteger)row;

@end


NS_ASSUME_NONNULL_END

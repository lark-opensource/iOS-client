//
//  AWEASMusicCellProtocol.h
//  Pods
//
//  Created by songxiangwu on 2019/5/15.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>


NS_ASSUME_NONNULL_BEGIN

@class AWESingleMusicView;
@protocol AWEASMusicCellProtocol <NSObject>

@property (nonatomic, assign) BOOL isEliteVersion;  // TODO: 看起来没啥用，后续确定下能删不
@property (nonatomic, assign) BOOL showMore;        // TODO: 看起来没啥用，后续确定下能删不
@property (nonatomic, assign) BOOL showClipButton;  // 展示"裁剪"按钮

@property (nonatomic, strong) AWESingleMusicView *musicView;
@property (nonatomic, copy) void (^tapWhileLoadingBlock)(void);

/// 使用音乐
@property (nonatomic, copy) void(^confirmBlock)(id<ACCMusicModelProtocol> _Nullable music, NSError * _Nullable error);

/// 点击“更多”按钮
@property (nonatomic, copy) void(^moreButtonClicked)(id<ACCMusicModelProtocol> _Nullable audio);

/// 收藏音乐
@property (nonatomic, copy) void(^favouriteBlock)(id<ACCMusicModelProtocol> _Nullable audio);

/// 裁剪音乐
@property (nonatomic, copy) void(^clipBlock)(id<ACCMusicModelProtocol> _Nullable audio, NSError * _Nullable error);

/// 是否允许裁剪音乐
@property (nonatomic, copy) BOOL(^enableClipBlock)(id<ACCMusicModelProtocol> audio);

@end

NS_ASSUME_NONNULL_END

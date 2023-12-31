//
//  ACCEditViewControllerInputData.h
//  Pods
//
//  Created by songxiangwu on 2019/9/6.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreativeKit/ACCBusinessConfiguration.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWEEditAndPublishCancelBlock)(void);

@protocol ACCMusicModelProtocol;
@class ACCImageAlbumEditInputData;
@interface ACCEditViewControllerInputData : NSObject <ACCBusinessInputData>

@property (nonatomic, strong) AWEVideoPublishViewModel *sourceModel; // 来源model同指针，而不像publishModel是copy
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, weak) AWEVideoPublishViewModel *recorderPublishModel; // 用于同步数据使用，使用场景: 拍摄页<->编辑页 跳转时。
@property (nonatomic, strong) ACCImageAlbumEditInputData *_Nullable imageAlbumEditInputData;
@property (nonatomic, strong) UIImage *coverImage;     // 首帧
@property (nonatomic, assign) BOOL showGuideBubble;
@property (nonatomic, assign) BOOL playImmediately;
@property (nonatomic, assign) BOOL enterFromShoot;

@property (nonatomic, strong) RACSignal *sourceDataSignal;

@property (nonatomic, copy) AWEEditAndPublishCancelBlock cancelBlock; // nav dismiss 时的回调。

@property (nonatomic, strong) id<ACCMusicModelProtocol> music;
@property (nonatomic, copy) NSArray<id<ACCMusicModelProtocol>> *musicList;

@end

NS_ASSUME_NONNULL_END

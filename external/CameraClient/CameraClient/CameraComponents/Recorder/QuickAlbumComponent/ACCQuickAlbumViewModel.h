//
//  ACCQuickAlbumViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by fengming.shi on 2020/12/8 18:03.
//	Copyright © 2020 Bytedance. All rights reserved.
	

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCQuickAlbumViewModel : ACCRecorderViewModel

@property (nonatomic, strong, readonly) RACSignal *quickAlbumShowOrHideSignal;
@property (nonatomic, strong, readonly) RACSignal *quickAlbumShowStateSignal;

- (void)quickAlbumShowStateChange:(BOOL)isShow;

- (void)showOrHideQuickAlbum:(BOOL)show;
- (void)showOrHideQuickAlbum:(BOOL)show isBlank:(BOOL)isBlank;

// TODO: 这里设计有点问题，用了signal但写成了命令式
@property (nonatomic) BOOL isQuickAlbumShow;
- (BOOL)currentRecordModeCanShow;

@end

NS_ASSUME_NONNULL_END

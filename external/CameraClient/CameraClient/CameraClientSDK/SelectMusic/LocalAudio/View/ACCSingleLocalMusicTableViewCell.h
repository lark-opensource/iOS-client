//
//  ACCSingleLocalMusicTableViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/2.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import "ACCPropRecommendMusicProtocol.h"

//cell右边功能区类型
typedef NS_ENUM(NSUInteger, ACCSingleLocalMusicCellStatus) {
    ACCSingleLocalMusicCellStatusNormal = 0,
    ACCSingleLocalMusicCellStatusShowApply,
    ACCSingleLocalMusicCellStatusShowEdit
};

typedef void (^ACCLocalMusicConfirmBlock)(id<ACCMusicModelProtocol> _Nullable audio);
typedef void (^ACCLocalMusicClipBlock)(id<ACCMusicModelProtocol> _Nullable audio);
typedef void (^ACCLocalMusicDeleteBlock)(id<ACCMusicModelProtocol> _Nullable audio);
typedef void (^ACCLocalMusicRenameBlock)(id<ACCMusicModelProtocol> _Nullable audio);

NS_ASSUME_NONNULL_BEGIN

@interface ACCSingleLocalMusicTableViewCell : UITableViewCell
@property (nonatomic, strong) id<ACCMusicModelProtocol> musicModel;

@property (nonatomic, copy) ACCLocalMusicConfirmBlock confirmAction;
@property (nonatomic, copy) ACCLocalMusicClipBlock clipAction;
@property (nonatomic, copy) ACCLocalMusicRenameBlock renameAction;
@property (nonatomic, copy) ACCLocalMusicDeleteBlock deleteAction;

@property (nonatomic, assign) BOOL disableClipButton;

+ (CGFloat)sectionHeight;

- (void)bindMusicModel:(id<ACCMusicModelProtocol>)model;
    
- (void)configWithEditStatus:(BOOL)isEdit;

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus;

- (void)configWithPlayerStatus:(ACCAVPlayerPlayStatus)playerStatus animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

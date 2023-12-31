//
//  OPVideoControlViewModel.m
//  OPPluginBiz
//
//  Created by baojianjun on 2022/4/20.
//

#import "OPVideoControlViewModel.h"
#import "TMAPlayerModel.h"

@interface OPVideoControlViewModel ()

@property (nonatomic, assign) OPVideoControlViewState viewShowingState;
@property (nonatomic, assign) OPVideoControlViewPlayBtnPosition playBtnPosition;
@property (nonatomic, assign, readwrite) BOOL enableProgressGesture;
@property (nonatomic, assign, readwrite) BOOL enablePlayGesture;

@end

@implementation OPVideoControlViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _viewShowingState = OPVideoControlViewStateNone;
    }
    return self;
}

- (void)updateWithPlayerModel:(TMAPlayerModel *)playerModel {
    OPVideoControlViewState state = OPVideoControlViewStateNone;
    if (playerModel.showPlayBtn) {
        state |= OPVideoControlViewStateShowStartBtn;
        if ([playerModel.playBtnPosition isEqualToString:@"center"]) {
            self.playBtnPosition = OPVideoControlViewPlayBtnCenter;
        } else {
            self.playBtnPosition = OPVideoControlViewPlayBtnBottom;
        }
    } else {
        self.playBtnPosition = OPVideoControlViewPlayBtnNotShow;
    }
    if (playerModel.showMuteBtn) {
        state |= OPVideoControlViewStateShowMuteBtn;
    }
    if (playerModel.showFullscreenBtn) {
        state |= OPVideoControlViewStateShowFullScreenBtn;
    }
    if (playerModel.showScreenLockButton) {
        state |= OPVideoControlViewStateShowLockBtn;
    }
    if (playerModel.showSnapshotButton) {
        state |= OPVideoControlViewStateShowSnapshotBtn;
    }
    if (playerModel.showRateButton) {
        state |= OPVideoControlViewStateShowRateBtn;
    }
    if (playerModel.showProgress) {
        state |= OPVideoControlViewStateShowProgress;
    }
    if (playerModel.showBottomProgress) {
        state |= OPVideoControlViewStateShowBottomProgress;
    }
    self.viewShowingState = state;
    self.enablePlayGesture = playerModel.enablePlayGesture;
    self.enableProgressGesture = playerModel.enableProgressGesture;
}

- (BOOL)showPlayBtnAtBottom {
    return OPVideoControlViewPlayBtnBottom == self.playBtnPosition;
}

- (BOOL)showPlayBtnAtCenter {
    return OPVideoControlViewPlayBtnCenter == self.playBtnPosition;
}

- (BOOL)showMuteBtn {
    return self.viewShowingState & OPVideoControlViewStateShowMuteBtn;
}

- (BOOL)showFullScreenBtn {
    return self.viewShowingState & OPVideoControlViewStateShowFullScreenBtn;
}

- (BOOL)showLockBtn {
    return (self.viewShowingState & OPVideoControlViewStateShowLockBtn) && self.isFullScreen;
}

- (BOOL)showSnapshotBtn {
    return (self.viewShowingState & OPVideoControlViewStateShowSnapshotBtn) && self.isFullScreen;
}

- (BOOL)showRateBtn {
    return self.viewShowingState & OPVideoControlViewStateShowRateBtn;
}

- (BOOL)showProgress {
    return self.viewShowingState & OPVideoControlViewStateShowProgress;
}

- (BOOL)showBottomProgress {
    return self.viewShowingState & OPVideoControlViewStateShowBottomProgress;
}

@end

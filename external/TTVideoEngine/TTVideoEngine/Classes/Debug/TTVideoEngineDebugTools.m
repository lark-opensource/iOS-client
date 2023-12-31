//
//  TTVideoEngineDebugTools.m
//  Article
//
//  Created by jiangyue on 2020/4/1.
//

#import "TTVideoEngineDebugVideoInfoBusiness.h"
#import "TTVideoEngineDebugTools.h"

@interface TTVideoEngineDebugTools ()

@property (nonatomic, strong) UIView *hudView;
@property (nonatomic, strong) TTVideoEngineDebugVideoInfoBusiness *infoBusiness;

@end

@implementation TTVideoEngineDebugTools

- (void)setDebugInfoView:view {
    if(self.debugToolsEnable){
        self.hudView = view;
    }
}

- (void)setIsFullScreen:(BOOL)isFullScreen {
     if(self.debugToolsEnable){
         _isFullScreen = isFullScreen;
         self.infoBusiness.isFullScreen = isFullScreen;
     }
}

- (void)start {
    if(self.debugToolsEnable){
        self.infoBusiness = [[TTVideoEngineDebugVideoInfoBusiness alloc] init];
        self.infoBusiness.indexForSuperView = self.indexForSuperView;
        [self.infoBusiness setPlayer:_videoEngine view:_hudView];
    }
}

- (void)show {
     if(self.debugToolsEnable){
         [self.infoBusiness showDebugVideoInfoView];
     }
}

- (void)hide {
    if(self.debugToolsEnable){
        [self.infoBusiness hideDebugVideoInfoView];
    }
}

- (void)remove {
    if(self.debugToolsEnable){
        [self.infoBusiness removeDebugVideoInfoView];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)setVideoEngine:(TTVideoEngine *)videoEngine {
    if(self.debugToolsEnable){
        _videoEngine = videoEngine;
    }
}

- (BOOL)videoDebugInfoViewIsShowing {
    if(self.debugToolsEnable){
        return [self.infoBusiness videoInfoViewIsShowing];
    }
    return NO;
}

@end

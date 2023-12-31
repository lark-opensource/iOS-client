//
//  ACCMusicPanelViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/6/25.
//

#import "ACCMusicPanelViewModel.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "AWERepoContextModel.h"
#import "ACCCommerceServiceProtocol.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>


@interface ACCMusicPanelViewModel ()

@property (nonatomic, strong) AWEVideoPublishViewModel *publishViewModel;

@end

@implementation ACCMusicPanelViewModel

#pragma mark - life cycle

- (void)dealloc {
    
}

- (instancetype)initWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel {
    if (self = [super init]) {
        self.publishViewModel = publishViewModel;
        self.showPanelAutoSelectedMusic = YES;
        self.trackFirstShowMusicType = NO;
        self.trackFirstDismissMusicType = NO;
    }
    return self;
}

#pragma mark - public

- (BOOL)enableMusicPanelVertical {
    return ACCConfigBool(kConfigBool_studio_music_panel_vertical);
}

+ (BOOL)enableNewMusicPanelUnification {
    return NO;
//    BOOL musicPanelUnification = ACCConfigBool(kConfigBool_studio_music_panel_unification);
//    return musicPanelUnification;
}

- (BOOL)enableCheckbox {
    BOOL musicPanelCheckbox = ACCConfigBool(kConfigBool_studio_music_panel_checkbox);
    return musicPanelCheckbox && ![IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.publishViewModel];
}

+ (BOOL)autoSelectedMusic {
    BOOL musicPanelEnableFirstSong = ACCConfigBool(kConfigBool_studio_music_panel_enable_first_song);
    return musicPanelEnableFirstSong;
}

- (BOOL)shouldShowMusicPanelTabOnly {
    // 图集相册无音量选择，不持歌词贴纸，音乐剪辑
    if ([self enableMusicPanelVertical]) {
        // 垂直布局：图集支持取消音乐时，展示底部tab
        return self.publishViewModel.repoImageAlbumInfo.isImageAlbumEdit && !ACCConfigBool(kConfigBool_image_mode_support_delete_music);
    } else {
        // 水平布局：图集不支持展示底部tab
        return self.publishViewModel.repoImageAlbumInfo.isImageAlbumEdit;
    }
}

- (NSString *)deselectedMusicToast {
    if (AWEVideoTypePhotoToVideo == self.publishViewModel.repoContext.videoType && !ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize)) {
        return ACCLocalizedString(@"creation_singlepic_cancelmusic", @"Cannot cancel a music under a single picture");
    } else if (self.publishViewModel.repoImageAlbumInfo.isImageAlbumEdit && !ACCConfigBool(kConfigBool_image_mode_support_delete_music)) {
        return @"图片作品不支持取消配乐";
    }
    return @"";
}
#pragma mark - music panel

- (void)resetPanelShowStatus:(BOOL)status {
    self.bgmMusicDisable = status;
    self.isShowing = status;
    self.showPanelScrollToSelectItem = status;
}

#pragma mark - private

@end


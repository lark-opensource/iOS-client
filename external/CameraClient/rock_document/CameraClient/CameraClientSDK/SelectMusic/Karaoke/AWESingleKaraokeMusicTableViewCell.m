//
//  AWESingleKaraokeMusicTableViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/4/2.
//

#import "AWESingleKaraokeMusicTableViewCell.h"

#import "AWESingleKaraokeMusicView.h"
#import <CreativeKit/ACCMacros.h>


@implementation AWESingleKaraokeMusicTableViewCell

@synthesize musicView = _karaokeMusicView;

- (AWESingleMusicView *)musicView
{
    if (!_karaokeMusicView) {
        _karaokeMusicView = [[AWESingleKaraokeMusicView alloc] init];
        _karaokeMusicView.contentPadding = kMusicViewContentPadding;
        _karaokeMusicView.delegate = self;
    }
    return _karaokeMusicView;
}

#pragma mark - Protocols
#pragma mark AWESingleMusicViewDelegate

- (void)singleMusicViewDidTapUse:(AWESingleMusicView *)musicView music:(id<ACCMusicModelProtocol>)music
{
    ACCBLOCK_INVOKE(self.confirmBlock, music, nil);
}

@end


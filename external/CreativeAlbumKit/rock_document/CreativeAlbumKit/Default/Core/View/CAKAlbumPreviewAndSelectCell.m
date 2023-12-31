//
//  CAKAlbumPreviewAndSelectCell.m
//  AWEStudio-Pods-Aweme
//
//  Created by xulei on 2020/3/15.
//

#import "CAKAlbumPreviewAndSelectCell.h"
#import "CAKAlbumAssetModel.h"

@interface CAKAlbumPreviewAndSelectCell ()


@end

@implementation CAKAlbumPreviewAndSelectCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)configCellWithAsset:(CAKAlbumAssetModel *)assetModel withPlayFrame:(CGRect)playFrame greyMode:(BOOL)greyMode{
    self.assetModel = assetModel;
}

- (void)removeCoverImageView{
}

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer withPlayerFrame:(CGRect)playerFrame{
}

- (UIScrollView *)zoomScrollView
{
    if (!_zoomScrollView) {
        _zoomScrollView = [[UIScrollView alloc] initWithFrame:self.contentView.bounds];
        _zoomScrollView.zoomScale = 1.0;
        _zoomScrollView.maximumZoomScale = 10;
        _zoomScrollView.minimumZoomScale = 1.0;
    }
    return _zoomScrollView;
}

@end

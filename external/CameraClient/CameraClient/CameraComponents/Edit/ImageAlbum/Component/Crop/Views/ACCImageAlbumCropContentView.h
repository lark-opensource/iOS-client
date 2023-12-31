//
//  ACCImageAlbumCropContentView.h
//  Indexer
//
//  Created by admin on 2021/11/11.
//

#import <UIKit/UIKit.h>
#import "ACCImageAlbumItemModel.h"

@protocol ACCImageAlbumCropContentViewDelegate <NSObject>

- (void)didEndZoom:(CGFloat)zoomScale;

@end

@interface ACCImageAlbumCropContentView : UIView

@property (nonatomic, weak) id<ACCImageAlbumCropContentViewDelegate> _Nullable delegate;
@property (nonatomic, assign, readonly) CGFloat zoomScale;
@property (nonatomic, assign, readonly) CGPoint contentOffset;
@property (nonatomic, assign, readonly) CGRect accessCropRect;

- (instancetype)initWithData:(ACCImageAlbumItemModel *)imageAlbumItem;
- (void)updateCropView:(ACCImageAlbumItemCropRatio)cropRatio;

@end

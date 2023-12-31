//
//  ACCImageAlbumCropControlView.h
//  Indexer
//
//  Created by admin on 2021/11/11.
//

#import <UIKit/UIKit.h>
#import "ACCImageAlbumItemModel.h"

@protocol ACCImageAlbumCropControlDelegate <NSObject>

- (void)closeCrop;
- (void)confirmCropRatio:(ACCImageAlbumItemCropRatio)cropRatio;
- (void)selectCropRatio:(ACCImageAlbumItemCropRatio)cropRatio;

@end

@interface ACCImageAlbumCropControlView : UIView

@property (nonatomic, weak) id<ACCImageAlbumCropControlDelegate> _Nullable delegate;

- (instancetype)initWithData:(ACCImageAlbumItemCropInfo *)cropInfo;

@end

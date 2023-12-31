//
//  AWEMattingCollectionViewCell.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/5/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEStudioBaseCollectionViewCell.h"
@class AWEAlbumImageModel;

@interface AWEMattingCollectionViewCell : AWEStudioBaseCollectionViewCell

@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, assign) BOOL customSelected;
@property (nonatomic, strong) AWEAlbumImageModel *faceModel;
@property (nonatomic, assign) BOOL enableMultiAssetsSelection;

- (void)configWithAlbumFaceModel:(AWEAlbumImageModel *)faceModel;
- (void)doMultiAssetsSelection;

@end

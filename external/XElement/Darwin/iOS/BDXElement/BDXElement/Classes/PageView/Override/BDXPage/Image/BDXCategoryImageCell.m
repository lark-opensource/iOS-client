//
//  BDXCategoryImageCell.m
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/20.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryImageCell.h"
#import "BDXCategoryImageCellModel.h"

@interface BDXCategoryImageCell()
@property (nonatomic, strong) NSString *currentImageName;
@property (nonatomic, strong) NSURL *currentImageURL;
@end

@implementation BDXCategoryImageCell

- (void)prepareForReuse {
    [super prepareForReuse];

    self.currentImageName = nil;
    self.currentImageURL = nil;
}

- (void)initializeViews {
    [super initializeViews];

    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_imageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    BDXCategoryImageCellModel *myCellModel = (BDXCategoryImageCellModel *)self.cellModel;
    self.imageView.bounds = CGRectMake(0, 0, myCellModel.imageSize.width, myCellModel.imageSize.height);
    self.imageView.center = self.contentView.center;
    if (myCellModel.imageCornerRadius && (myCellModel.imageCornerRadius != 0)) {
        self.imageView.layer.cornerRadius = myCellModel.imageCornerRadius;
        self.imageView.layer.masksToBounds = YES;
    }
}

- (void)reloadData:(BDXCategoryBaseCellModel *)cellModel {
    [super reloadData:cellModel];

    BDXCategoryImageCellModel *myCellModel = (BDXCategoryImageCellModel *)cellModel;

    NSString *currentImageName;
    NSURL *currentImageURL;
    if (myCellModel.imageName) {
        currentImageName = myCellModel.imageName;
    } else if (myCellModel.imageURL) {
        currentImageURL = myCellModel.imageURL;
    }
    if (myCellModel.isSelected) {
        if (myCellModel.selectedImageName) {
            currentImageName = myCellModel.selectedImageName;
        } else if (myCellModel.selectedImageURL) {
            currentImageURL = myCellModel.selectedImageURL;
        }
    }
    if (currentImageName && ![currentImageName isEqualToString:self.currentImageName]) {
        self.currentImageName = currentImageName;
        self.imageView.image = [UIImage imageNamed:currentImageName];
    } else if (currentImageURL && ![currentImageURL.absoluteString isEqualToString:self.currentImageURL.absoluteString]) {
        self.currentImageURL = currentImageURL;
        if (myCellModel.loadImageCallback) {
            myCellModel.loadImageCallback(self.imageView, currentImageURL);
        }
    }

    if (myCellModel.isImageZoomEnabled) {
        self.imageView.transform = CGAffineTransformMakeScale(myCellModel.imageZoomScale, myCellModel.imageZoomScale);
    }else {
        self.imageView.transform = CGAffineTransformIdentity;
    }
}

@end

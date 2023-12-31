//
//  BDXCategoryTitleImageView.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/8.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryTitleView.h"
#import "BDXCategoryTitleImageCell.h"
#import "BDXCategoryTitleImageCellModel.h"

@interface BDXCategoryTitleImageView : BDXCategoryTitleView

@property (nonatomic, strong) NSArray <NSString *>*imageNames;

@property (nonatomic, strong) NSArray <NSString *>*selectedImageNames;

@property (nonatomic, strong) NSArray <NSURL *>*imageURLs;

@property (nonatomic, strong) NSArray <NSURL *>*selectedImageURLs;

@property (nonatomic, strong) NSArray <NSNumber *> *imageTypes;

@property (nonatomic, copy) void(^loadImageCallback)(UIImageView *imageView, NSURL *imageURL);

@property (nonatomic, assign) CGSize imageSize;

@property (nonatomic, assign) CGFloat titleImageSpacing;

@property (nonatomic, assign, getter=isImageZoomEnabled) BOOL imageZoomEnabled;

@property (nonatomic, assign) CGFloat imageZoomScale;

@end

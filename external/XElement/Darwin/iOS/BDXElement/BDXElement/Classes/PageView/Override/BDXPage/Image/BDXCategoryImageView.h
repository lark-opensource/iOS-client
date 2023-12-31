//
//  BDXCategoryImageView.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/20.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryIndicatorView.h"
#import "BDXCategoryImageCell.h"
#import "BDXCategoryImageCellModel.h"

@interface BDXCategoryImageView : BDXCategoryIndicatorView

@property (nonatomic, strong) NSArray <NSString *>*imageNames;

@property (nonatomic, strong) NSArray <NSURL *>*imageURLs;

@property (nonatomic, strong) NSArray <NSString *>*selectedImageNames;

@property (nonatomic, strong) NSArray <NSURL *>*selectedImageURLs;

@property (nonatomic, copy) void(^loadImageCallback)(UIImageView *imageView, NSURL *imageURL);

@property (nonatomic, assign) CGSize imageSize;     //default CGSizeMake(20, 20)

@property (nonatomic, assign) CGFloat imageCornerRadius;

@property (nonatomic, assign, getter=isImageZoomEnabled) BOOL imageZoomEnabled;     //default NO

@property (nonatomic, assign) CGFloat imageZoomScale;    

@end

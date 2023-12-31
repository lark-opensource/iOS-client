//
//  BDXCategoryTitleImageCellModel.h
//  BDXCategoryView
//
//  Created by jiaxin on 2018/8/8.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "BDXCategoryTitleCellModel.h"

typedef NS_ENUM(NSUInteger, BDXCategoryTitleImageType) {
    BDXCategoryTitleImageType_TopImage = 0,
    BDXCategoryTitleImageType_LeftImage,
    BDXCategoryTitleImageType_BottomImage,
    BDXCategoryTitleImageType_RightImage,
    BDXCategoryTitleImageType_OnlyImage,
    BDXCategoryTitleImageType_OnlyTitle,
};

@interface BDXCategoryTitleImageCellModel : BDXCategoryTitleCellModel

@property (nonatomic, assign) BDXCategoryTitleImageType imageType;

@property (nonatomic, copy) void(^loadImageCallback)(UIImageView *imageView, NSURL *imageURL);

@property (nonatomic, copy) NSString *imageName;

@property (nonatomic, strong) NSURL *imageURL;

@property (nonatomic, copy) NSString *selectedImageName;

@property (nonatomic, strong) NSURL *selectedImageURL;

@property (nonatomic, assign) CGSize imageSize;

@property (nonatomic, assign) CGFloat titleImageSpacing;    

@property (nonatomic, assign, getter=isImageZoomEnabled) BOOL imageZoomEnabled;

@property (nonatomic, assign) CGFloat imageZoomScale;

@end

//
//  AWEDouyinStickerCategoryModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/5.
//

#import "AWEStickerCategoryModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEDouyinStickerCategoryModel : AWEStickerCategoryModel

@property (nonatomic, copy, readonly) NSArray<NSString *> *selectedIconUrls;

@property (nonatomic, strong) UIImage *image;
// cell 用来显示的 title
//@property (nonatomic, copy, readonly) NSString *title;

@property (nonatomic, assign) CGRect titleFrame;
@property (nonatomic, assign) CGRect imageFrame;
@property (nonatomic, assign) CGSize cellSize;


+ (instancetype)favoriteCategoryModel;

+ (instancetype)searchCategoryModel;

@end

NS_ASSUME_NONNULL_END

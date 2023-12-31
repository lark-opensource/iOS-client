//
//  AWEStickerPickerCategoryBaseCell.h
//  Pods
//
//  Created by Chipengliu on 2020/8/20.
//

#import <UIKit/UIKit.h>
#import "AWEStickerCategoryModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerCategoryBaseCell : UICollectionViewCell

@property (nonatomic, strong) AWEStickerCategoryModel *categoryModel;

/// 当分类下的特效有添加/删减，会调用改方法
- (void)categoryDidUpdate;

@end

NS_ASSUME_NONNULL_END

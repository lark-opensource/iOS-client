//
//  DVEPickerCategoryBaseCell.h
//  Pods
//
//  Created by bytedance on 2020/8/20.
//

#import <UIKit/UIKit.h>
#import "DVEPickerViewModels.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEPickerCategoryBaseCell : UICollectionViewCell

@property (nonatomic, strong) id<DVEPickerCategoryModel> categoryModel;

/// 当分类下的特效有添加/删减，会调用改方法
- (void)categoryDidUpdate;

@end

NS_ASSUME_NONNULL_END

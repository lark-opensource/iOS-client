//
//   DVEModuleBaseCategoryModel.h
//   NLEEditor
//
//   Created  by bytedance on 2021/5/20.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import <Foundation/Foundation.h>
#import "DVEPickerViewModels.h"
#import "DVEEffectCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEModuleBaseCategoryModel : NSObject <DVEPickerCategoryModel>

@property(nonatomic,strong)DVEEffectCategory *category;

@end

NS_ASSUME_NONNULL_END

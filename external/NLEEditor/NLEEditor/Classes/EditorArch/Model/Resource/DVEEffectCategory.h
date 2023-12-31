//
//   DVEEffectCategory.h
//   NLEEditor
//
//   Created  by bytedance on 2021/5/21.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
 
#import "DVEResourceCategoryModelProtocol.h"
#import "DVEEffectValue.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEEffectCategory : NSObject<DVEResourceCategoryModelProtocol>

///模型列表
@property(nonatomic,copy)NSArray<DVEEffectValue*>* models;

@end

NS_ASSUME_NONNULL_END

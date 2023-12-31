//
//  ACCMomentAIMomentModel.h
//  Pods
//
//  Created by Pinka on 2020/5/25.
//

#import <Mantle/Mantle.h>
#import "ACCMomentReframe.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCMomentAIMomentModel : MTLModel

/// Moment id
@property (nonatomic, copy) NSString *identity;

/// <#Description#>
@property (nonatomic, copy) NSString *type;

/// Title | 标题，日期规则：YYYY-MM-DD_XX·XXXX
@property (nonatomic, copy) NSString *title;

/// <#Description#>
@property (nonatomic, assign) NSInteger version;

/// Material PHAsset id list | 素材的PHAsset id列表
@property (nonatomic, copy  ) NSArray<NSString *> *materialIds;

/// Template id | 模版id
@property (nonatomic, assign) int64_t templateId;

/// 时光类1, 精品5, 普通15
@property (nonatomic, assign) NSInteger momentSource;

/// New moment flag | 是否为新的moment
@property (nonatomic, assign) BOOL isNew;

/// Update mement flag | 是否为有更新的moment
@property (nonatomic, assign) BOOL isUpdate;

/// Cover material's PHAsset id | 封面的PHAsset id
@property (nonatomic, copy  ) NSString *coverMaterialId;

/// Cover's reframes | 封面的剪裁信息
@property (nonatomic, copy  ) NSArray<ACCMomentReframe *> *coverReframes;

/// Effect Id
@property (nonatomic, copy) NSString *effectId;

/// Extra Info
@property (nonatomic, copy) NSString *extra;

#pragma mark -
@property (nonatomic, copy  ) NSArray<NSNumber *> *uids;

@property (nonatomic, assign) NSUInteger coverUid;

@end

NS_ASSUME_NONNULL_END

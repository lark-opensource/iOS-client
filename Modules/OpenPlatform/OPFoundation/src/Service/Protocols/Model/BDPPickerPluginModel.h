//
//  BDPPickerPluginModel.h
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDPBaseJSONModel.h"

FOUNDATION_EXTERN const NSInteger BDPPickerColumnNotUpdate;

NS_ASSUME_NONNULL_BEGIN

/**
 * 显示picker的信息模型
 */
@interface BDPPickerPluginModel : BDPBaseJSONModel

/// 当前picker需要显示的数据模型数组
@property (nonatomic, copy) NSArray<NSArray<NSString *> *> *components;
/// 每一个components当前选择的是哪一个
@property (nonatomic, copy) NSArray<NSNumber *> *selectedRows;
/// 要更新哪一列
@property (nonatomic, assign) NSInteger column;

- (void)updateWithModel:(BDPPickerPluginModel *)model;

@end

NS_ASSUME_NONNULL_END

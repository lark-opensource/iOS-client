//
//  ADFeelGoodInfo.h
//  ADFeelGood
//
//  Created by cuikeyi on 2021/2/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// FeelGood trigger 信息模型
@interface ADFeelGoodInfo : NSObject

/// Event taskid
@property (nonatomic, copy, readonly, nullable) NSString *taskID;
/// triggerEvent返回的数据
@property (nonatomic, strong, readonly, nullable) NSDictionary *triggerResult;
/// 是否为全局弹框
@property (nonatomic, assign, readonly, getter=isGlobalDialog) BOOL globalDialog;

// 构建方法
+ (ADFeelGoodInfo *)createInfoModel:(NSString *)taskID triggerResult:(nullable NSDictionary *)triggerResult globalDialog:(BOOL)globalDialog;

@end

NS_ASSUME_NONNULL_END

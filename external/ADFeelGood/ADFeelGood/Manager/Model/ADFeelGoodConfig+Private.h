//
//  ADFeelGoodConfig+Private.h
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/14.
//

#import "ADFeelGoodConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface ADFeelGoodConfig (Private)

/// 获取请求通参
/// @param eventID 用户行为事件标识
/// @param extraUserInfo 自定义用户标识，请求时添加到user字典中
- (NSMutableDictionary *)checkQuestionParamsWithEventID:(NSString *)eventID extraUserInfo:(NSDictionary *)extraUserInfo;

/// 加载H5使用的参数
/// @param taskID 问卷的ID
/// @param taskSetting 问卷设置信息
/// @param extraUserInfo 自定义用户标识，请求时添加到user字典中
- (NSMutableDictionary *)webviewParamsWithTaskID:(NSString *)taskID taskSetting:(NSDictionary *)taskSetting extraUserInfo:(NSDictionary *)extraUserInfo;

- (NSString *)headerOrigin;

@end

NS_ASSUME_NONNULL_END

//
//  ADFGWebModel.h
//  ADFeelGood
//
//  Created by cuikeyi on 2021/3/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 配合 ADFGWebView 的模型
@interface ADFGWebModel : NSObject

/// 自定义用户标识，请求时添加到user字典中
@property (nonatomic, strong, nullable) NSDictionary *extraUserInfo;
/// 外部设置超时时间
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
/// 设置webview.scrollView.scrollEnabled，默认为YES
@property (nonatomic, assign) BOOL scrollEnabled;

#pragma mark - 业务透传
// 当业务方设置了参数showLocalSubmitRecord=true时， H5通过JSBridge getParams读取到showLocalSubmitRecord的值并自行按需判断是否需要显示已提交状态；默认为false
@property (nonatomic, assign) BOOL showLocalSubmitRecord;
/// taskID，不传默认取 taskSettingDict[@"survey_task"][@"task_id"]
@property (nonatomic, copy) NSString *taskID;
/// web页调用getParams时，透传至taskSetting字段
@property (nonatomic, strong) NSDictionary *taskSettingDict;
///
@property (nonatomic, assign) BOOL isExpired;

@end

NS_ASSUME_NONNULL_END

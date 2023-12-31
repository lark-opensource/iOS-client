//
//  CJPayHybridBaseConfig.h
//  Aweme
//
//  Created by wangxiao on 2023/1/12.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HybridEngineType);

@class HybridContext;
@interface CJPayHybridBaseConfig : JSONModel

#pragma mark - ------------------ 基础配置参数 ------------------
// scheme
@property (nonatomic, copy) NSString *scheme;
// url:最终加载的链接
@property (nonatomic, copy) NSString *url;
// 打开是否有动画
@property (nonatomic, assign) BOOL openAnimate;
// 云控settings的key，多个key用英文逗号隔开
@property (nonatomic, copy) NSString *cjSettingsKeys;
// 实验absettings的key，多个key用英文逗号隔开
@property (nonatomic, copy) NSString *cjAbtestKeys;

// 是否支持左滑返回，仅全屏支持
@property (nonatomic, assign) BOOL hardware_back;
//自定义注入参数，解析
@property (nonatomic, copy) NSDictionary *initialParams;
//secLinkScene鉴权参数
@property (nonatomic, copy) NSString *secLinkScene;
//禁用侧滑返回
@property (nonatomic, assign) BOOL swipeDisable;
//web NavigationDelegate UIDelegate
@property (nonatomic, weak, nullable) NSObject *WKDelegate;
//open_method
@property (nonatomic, copy) NSString *openMethod;
#pragma mark - ------------------ 通用方法 ------------------

//构造hybrid专用数据结构
- (HybridContext *)toContext;
//容器类型
- (HybridEngineType)enginetype;


@end

NS_ASSUME_NONNULL_END

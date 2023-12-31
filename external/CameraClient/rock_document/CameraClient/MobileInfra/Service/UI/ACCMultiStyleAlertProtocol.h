//
//  ACCMultiStyleAlertProtocol.h
//  CameraClient-Pods-AwemeCore
//
//  Created by xzg on 2021/10/12.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CameraClient/ACCConfigKeyDefines.h>

 /// 差异部分，用于转换为其他协议类型
#define ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(obj, targetProto, diffBlock) if([obj conformsToProtocol:@protocol(targetProto)]) { \
^(id <targetProto> obj) { \
    diffBlock ? diffBlock() : nil; \
}((id <targetProto>)obj); \
}

@protocol ACCMultiStyleAlertBaseParamsProtocol, ACCMultiStyleAlertBaseActionProtocol;
typedef void(^ACCMultiStyleAlertConfigParamsBlock)(id<ACCMultiStyleAlertBaseParamsProtocol> _Nonnull params);
typedef void(^ACCMultiStyleAlertConfigActionBlock)(id<ACCMultiStyleAlertBaseActionProtocol> _Nonnull action);

 
#pragma mark - Base
 
typedef NS_ENUM(NSUInteger, ACCMultiStyleAlertActionStyle) {
    /// 默认样式
    ACCMultiStyleAlertActionStyleNormal,
    /// 突出样式（一般为红色）
    ACCMultiStyleAlertActionStyleHightlight
};
 
@protocol ACCMultiStyleAlertBaseActionProtocol;
typedef void(^ACCMultiStyleAlertActionEventBlock)(id<ACCMultiStyleAlertBaseActionProtocol> _Nonnull action);
 
@protocol ACCMultiStyleAlertBaseActionProtocol <NSObject>
 
/// 显示标题
@property (nonatomic, copy, nullable) NSString *title;
 
/// action的样式
@property (nonatomic, assign) ACCMultiStyleAlertActionStyle actionStyle;
 
/// 点击事件
@property (nonatomic, copy, nullable) ACCMultiStyleAlertActionEventBlock eventBlock;
 
@end
 
 
@protocol ACCMultiStyleAlertBaseParamsProtocol <NSObject>

/// 是否在show之前重新设置，会重新执行configBlock，用于实时刷新
@property (nonatomic, assign, getter=isReconfigBeforeShow) BOOL reconfigBeforeShow;

@property (nonatomic, strong, readonly, nullable) NSArray <id<ACCMultiStyleAlertBaseActionProtocol> > *actions;
 
/// 添加相关功能
- (void)addAction:(ACCMultiStyleAlertConfigActionBlock)actionConfigBlock;
 
@end
 
 
#pragma mark - Alert
 
@protocol ACCMultiStyleAlertNormalActionProtocol <ACCMultiStyleAlertBaseActionProtocol>
@end

@protocol ACCMultiStyleAlertNormalParamsProtocol <ACCMultiStyleAlertBaseParamsProtocol>
 
/// 标题
@property (nonatomic, copy, nullable) NSString *title;
 
/// 消息主题
@property (nonatomic, copy, nullable) NSString *message;
 
/// 按钮布局是否为垂直 （默认为水平）
@property (nonatomic, assign) BOOL isButtonAlignedVertically;
 
@end
 
 


#pragma mark - Sheet
 
@protocol ACCMultiStyleAlertSheetActionProtocol <ACCMultiStyleAlertBaseActionProtocol>
@end

@protocol ACCMultiStyleAlertSheetParamsProtocol <ACCMultiStyleAlertBaseParamsProtocol>
 
/// 标题
@property (nonatomic, copy, nullable) NSString *title;
 
/// 点击取消时的回调 取消按钮一直存在
@property (nonatomic, copy, nullable) void (^cancelEventBlock)(void);
 
@end
 
 
#pragma mark - Popover (气泡样式)
 
@protocol ACCMultiStyleAlertPopoverActionProtocol <ACCMultiStyleAlertBaseActionProtocol>
 
/// 图片
@property (nonatomic, strong, nullable) UIImage *image;
  
@end
 
 
/// 箭头指向的方向
typedef NS_ENUM(NSUInteger, ACCMultiStyleAlertPopoverArrowDirection) {
    ACCMultiStyleAlertPopoverArrowDirectionUp    = 0,
    ACCMultiStyleAlertPopoverArrowDirectionDown  = 1,
    ACCMultiStyleAlertPopoverArrowDirectionLeft  = 2,
    ACCMultiStyleAlertPopoverArrowDirectionRight = 3,
};
 
@protocol ACCMultiStyleAlertPopoverParamsProtocol <ACCMultiStyleAlertBaseParamsProtocol>
 
/// 弹窗上箭头指向的视图
@property (nonatomic, strong, nullable) UIView *sourceView;
 
/// 弹窗箭头指向的方框，箭头的箭尖会指向方框各边中心，方框的frame以sourceView为基准，可根据此调整弹窗偏移
@property (nonatomic, assign) CGRect sourceRect;
 
/// 气泡箭头方向
@property (nonatomic, assign) ACCMultiStyleAlertPopoverArrowDirection arrowDirection;
 
/// 自定义弹窗宽度
@property (nonatomic, assign) CGFloat fixedContentWidth;
 
/// 自定义弹窗高度
@property (nonatomic, assign) CGFloat fixedContentHeight;
 
/// 自定义弹窗偏移
@property (nonatomic, assign) CGFloat fixedOffsetY;
 
/// 内容对齐方式
@property (nonatomic, assign) UIControlContentHorizontalAlignment alignmentMode;
 
@end
 
 
#pragma mark - MultiSytleAlert协议
 
/// 可设样式的alert 目前支持  常规 Alert、ActionSheet、Bubble
@protocol ACCMultiStyleAlertProtocol <NSObject>
 
/// 参数
@property (nonatomic, strong, readonly, nullable) id <ACCMultiStyleAlertBaseParamsProtocol> params;
 
/// 配置视图
/// @param paramsProtocol 确定Alert类型的协议
/// @param configBlock 配置block
- (instancetype)initWithParamsProtocol:(Protocol * _Nonnull)paramsProtocol configBlock:(ACCMultiStyleAlertConfigParamsBlock _Nonnull)configBlock;

/// 埋点类型
- (NSString *)trackerType;

/// 显示
- (void)show;
 
/// 隐藏
- (void)dismiss;
 
@end
 
/// 挽留弹窗的样式协议 （线上样式根据各场景自定义，返回为空)
FOUNDATION_STATIC_INLINE Protocol *ACCMultiStyleAlertParamsProtocol(ACCRecordEditBegForStayPrompStyle style)
{
    switch (style) {
        case ACCRecordEditBegForStayPrompStyleOnline:
            return nil;
        case ACCRecordEditBegForStayPrompStyleSheet:
            return @protocol(ACCMultiStyleAlertSheetParamsProtocol);
        case ACCRecordEditBegForStayPrompStylePopover:
            return @protocol(ACCMultiStyleAlertPopoverParamsProtocol);
        case ACCRecordEditBegForStayPrompStyleAlert:
            return @protocol(ACCMultiStyleAlertNormalParamsProtocol);
            
    }
}

/// MultiStyleAlert实例
FOUNDATION_STATIC_INLINE id<ACCMultiStyleAlertProtocol> ACCMultiStyleAlert() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCMultiStyleAlertProtocol)];
}
 
 


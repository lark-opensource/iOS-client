//
//   BDUGActivityProtocol.h
//   BDUGActivityViewControllerDemo
//
//  Created by 延晋 张 on 16/6/1.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDUGActivityProtocol;

typedef void(^BDUGShareActivityDataReadyHandler)(BDUGShareDataItemModel * _Nullable item);

@protocol BDUGActivityDataSource <NSObject>

/**
 向外部请求数据状态，如果数据已经ready直接返回，如果数据没有ready等待数据ready之后返回。

 @param acticity 等待的activity
 @param dataIsReadyHandler 数据ready后的回调
 */
- (void)acticity:(id <BDUGActivityProtocol>)acticity waitUntilDataIsReady:(BDUGShareActivityDataReadyHandler)dataIsReadyHandler;

@end

typedef void(^ BDUGActivityCompletionHandler)(id <BDUGActivityProtocol> activity, NSError * _Nullable error, NSString * _Nullable  desc);
typedef void(^ BDUGActivityTokenDialogDidShow)(void);
typedef BOOL (^BDUGShareOpenThirPlatform)(void);

@protocol BDUGActivityProtocol <NSObject>

@required
//注意：需要在判断内容的分享有效性后赋值
@property (nonatomic, strong, nullable) id<BDUGActivityContentItemProtocol> contentItem;

//分享内容的标示key，用于和contentItem的相认匹配
- (NSString *)contentItemType;

//分享type 可用于分享结果中标识分享的类型
- (NSString *)activityType;

- (void)performActivityWithCompletion:(BDUGActivityCompletionHandler _Nullable)completion;

- (NSString * _Nullable )activityImageName;

- (NSString * _Nullable )contentTitle;

- (NSString * _Nullable )shareLabel;

@optional

- (BOOL)appInstalled;

@optional

@property (nonatomic, weak, nullable) UIViewController *presentingViewController;
@property (nonatomic, copy, nullable) BDUGActivityTokenDialogDidShow tokenDialogDidShowBlock;

//activity的分享数据来源。
@property (nonatomic, weak, nullable) id <BDUGActivityDataSource> dataSource;

//activity所属的panelId
@property (nonatomic, copy, nullable) NSString *panelId;

/*!
 *  @brief  调起分享的入口
 *
 *  @param contentItem              contentItem
 *  @param presentingViewController 有些分享需要present新页面
 *  @param onComplete               分享结果
 */
- (void)shareWithContentItem:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController * _Nullable)presentingViewController onComplete:(BDUGActivityCompletionHandler _Nullable)onComplete;

- (CGFloat)customWidth;

- (CGFloat)customItemWidth;

@end

NS_ASSUME_NONNULL_END

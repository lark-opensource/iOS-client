//
//   BDUGActivityPanelControllerProtocol.h
//  Pods
//
//  Created by 延晋 张 on 16/7/10.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"

@class BDUGShareManager;
@class BDUGSharePanelContent;
@protocol BDUGActivityPanelControllerProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol BDUGActivityPanelDelegate <NSObject>

- (void)activityPanel:(id<BDUGActivityPanelControllerProtocol>)panel
          clickedWith:(id<BDUGActivityProtocol> _Nullable)acitivity;

- (void)activityPanel:(id<BDUGActivityPanelControllerProtocol>)panel
        completedWith:(id<BDUGActivityProtocol> _Nullable)activity
                error:(NSError * _Nullable)error
                 desc:(NSString * _Nullable)desc;

- (void)activityPanelDidCancel:(id<BDUGActivityPanelControllerProtocol>)panel;

@end

@protocol BDUGActivityPanelControllerProtocol <NSObject>

@property (nonatomic, weak, nullable) id<BDUGActivityPanelDelegate> delegate;

/**
 *  展示panel
 */
- (void)show;
/**
 *  收起pannel
 */
- (void)hide;

@optional

/**
 *  构造一个PanelController
 *
 *  @param items       TTPanelControllerItem的数组的数组 @[@[item1, item2], @[item3, item4]]
 *  @param cancelTitle 取消button的title
 *
 *  @return TTPanelController
 */
- (instancetype)initWithItems:(NSArray <NSArray *> *)items cancelTitle:(NSString * _Nullable)cancelTitle;

- (instancetype)initWithItems:(NSArray <NSArray *> *)items panelContent:(BDUGSharePanelContent * _Nullable)panelContent;

@end

NS_ASSUME_NONNULL_END

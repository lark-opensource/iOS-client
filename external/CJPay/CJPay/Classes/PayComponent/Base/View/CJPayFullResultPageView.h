//
//  CJPayFullResultPageView.h
//  CJPaySandBox
//
//  Created by 高航 on 2022/11/25.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN
@class CJPayResultPageModel;
@interface CJPayFullResultPageView : UIView

@property (nonatomic, copy) void(^completion)(void);
@property (nonatomic, copy) void(^showGuideBlock)(void);
@property (nonatomic, copy) NSDictionary *trackerParams;


- (instancetype)initWithCJOrderModel:(CJPayResultPageModel *)model;
- (void)loadLynxCard;

@end

NS_ASSUME_NONNULL_END

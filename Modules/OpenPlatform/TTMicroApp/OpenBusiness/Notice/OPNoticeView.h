//
//  OPNoticeView.h
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/5.
//

#import <UIKit/UIKit.h>
#import "OPNoticeModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OPNoticeViewDelegate <NSObject>

-(void)didCloseNoticeView;

@end

@interface OPNoticeView : UIView

-(instancetype)initWithFrame:(CGRect)frame model:(OPNoticeModel *)model isAutoLayout:(BOOL)isAutoLayout;

@property (nonatomic,weak) id<OPNoticeViewDelegate> delegate;

@property (nonatomic,strong,readonly) OPNoticeModel *model;

@property (nonatomic, strong) NSString *appID; // 对于Web来说，view的生命周期和页面不一定一样，需要把状态周期相关的appID保存在这里

@property (nonatomic, assign) BOOL isAutoLayout;

-(void)didCloseNoticeView;

-(void)showMask;

@end

NS_ASSUME_NONNULL_END

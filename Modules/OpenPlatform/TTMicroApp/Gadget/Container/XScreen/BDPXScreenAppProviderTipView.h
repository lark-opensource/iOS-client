//
//  BDPXScreenAppProviderTipView.h
//  TTMicroApp
//
//  Created by qianhongqiang on 2022/8/10.
//

#import <UIKit/UIKit.h>
@class BDPXScreenAppProviderTipView;

@protocol BDPXScreenAppProviderTipViewDelegate <NSObject>

-(void)didClickAppProviderTipView:(BDPXScreenAppProviderTipView *)appProviderTipView;

@end

@interface BDPXScreenAppProviderTipView : UIView

@property (nonatomic,weak) id<BDPXScreenAppProviderTipViewDelegate> delegate;

- (void)updateAppName:(NSString *)appName iconURL:(NSString *)iconURL;

@end

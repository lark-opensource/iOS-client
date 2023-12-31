//
//  TTAdSplashViewButton.h
//  Article
//
//  Created by matrixzk on 10/30/15.
//
//

#import <UIKit/UIKit.h>
#import "TTAdSplashHeader.h"

/// 图片且半屏开屏下的 Banner 实现，具体 UI 可以参考：https://bytedance.feishu.cn/docs/doccn19xmXXkkIHtDVUqsIMCzYg#dSjoSo
@interface TTAdSplashViewButton : UIView

@property (nonatomic, copy) TTAdSplashViewButtonTapHandler buttonTapActionBlock;
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, strong, readonly) UILabel *titleLabel;

@end

//
//  TTAdSplashSubFieldModels.h
//  TTAdSplashSDK
//
//  Created by bytedance on 2021/1/12.
//

#import <Foundation/Foundation.h>
#import "TTAdSplashHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTAdSplashSwipeUpConfigModel : NSObject<NSCoding>

@property (nonatomic, assign) NSInteger swipeUpDistance;/// 滑动响应距离，小于此值会被识别为点击，大于等于则表示手势被消费，如果不下发默认为6
@property (nonatomic, assign) BDASplashViewSwipeUpMode swipeAction;/// 上滑跳过视图上滑手势的行为定义
@property (nonatomic, assign) BDASplashViewSwipeTapMode swipeTapAction;/// 点击上滑跳过视图点击时的行为定义
@property (nonatomic, copy) NSString *swipeUpText;///上滑跳过视图提示文案，为空则不展示
@property (nonatomic, assign) NSInteger swipeUpDuration;/// 上滑跳过视图展示时间，超过这个时间应该消失或者隐藏，单位毫秒，0 表示常驻
@property (nonatomic, strong) UIColor *swipeUpBackgroundColor;/// 上滑跳过视图的背景色，注意：可能为 nil

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END

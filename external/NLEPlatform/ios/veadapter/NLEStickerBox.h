//
//  NLEStickerBox.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 贴纸添加到播放器后的坐标信息
 */
@interface NLEStickerBox : NSObject

/*
 宽高
 */
@property (nonatomic, assign) CGSize size;

/*
 中心点
 */
@property (nonatomic, assign) CGPoint centerPoint;

/*
 旋转角度，单位是pi。直角是 1/2 pi，一周是 2 pi
 */
@property (nonatomic, assign) CGFloat rotatePI;

@end

NS_ASSUME_NONNULL_END

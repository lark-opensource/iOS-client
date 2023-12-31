//
//  ACCImageAlbumEditInputData.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

/**
 * 图集发布模式下的数据源
---------------------------------------------
 * 什么是图集发布模式？
 * 图集发布模式是选择两张或者以上纯图片时候回进入到图集发布模式
   以往是会合成MV视频，现在不会合成视频，而是对每张图片单独编辑
   发布的时候也是发布的纯图片，用户在消费端可滑动浏览编辑后的图片集
 
---------------------------------------------
 * 为什么需要这个？
   因为产品层面 图集发布模式下 图片编辑模式 和视频编辑模式可以相互切换，且数据互不相通，切再次切回来的时候之前的编辑效果还是要恢复
   所以在实现方案上我们选择了切换的时候 对navigation的整个编辑页VC进行替换，然后通过publishModel进行编辑页的恢复之前的编辑效果
   所以我们需要两个独立的 图片 和视频模式下的编辑数据
   因此我们需要【更上层】的一个可以记录两个模式下的数据，否则我们需要在一个publishModel里面去关联另一个publishModel，不是很合理
 */
@interface ACCImageAlbumEditInputData : NSObject <NSCopying>

@property (nonatomic, strong) AWEVideoPublishViewModel *imageModePublishModel;
@property (nonatomic, strong) AWEVideoPublishViewModel *videoModePublishModel;

@end

NS_ASSUME_NONNULL_END

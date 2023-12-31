//
//  AWEVoiceChangerCell.h
//  Pods
//
//  Created by chengfei xiao on 2019/5/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class IESEffectModel;

@interface AWEVoiceChangerCell : UICollectionViewCell

- (void)setThumbnailURLList:(NSArray *)thumbnailURLList;
- (void)setThumbnailURLList:(NSArray *)thumbnailURLList placeholder:(nullable UIImage *)placeholder;

- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated;
- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated completion:(nullable void (^)(BOOL))completion;
- (void)updateText:(NSString *)text;

//音效包太小1K不到，TCP最小数据长度为1460Bytes，一个包传完，progress回调1次就到1.0了，所以不能和道具下载的 progress 一样；
- (void)showLoadingAnimation:(BOOL)show;

@property (nonatomic, strong) IESEffectModel *currentEffect;
@property (nonatomic, assign) BOOL needChangeSelectedTitleColor;
@property (nonatomic, assign, readonly) BOOL isCurrent;

@end

NS_ASSUME_NONNULL_END

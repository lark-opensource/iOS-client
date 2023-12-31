//
//  AWEModernStickerTitleCellViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/10/26.
//

#import <Foundation/Foundation.h>
#import <ReactiveObjC/RACSignal.h>
#import <CreationKitInfra/IESCategoryModel+AWEAdditions.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEModernStickerTitleCellViewModel;

@protocol AWEModernStickerTitleCellViewModelCalculateDelegate <NSObject>

@required
- (void)modernStickerTitleCellViewModel:(AWEModernStickerTitleCellViewModel *)viewModel
                         frameWithTitle:(NSString * _Nullable)title
                                  image:(UIImage * _Nullable)image
                             completion:(void(^)(CGFloat cellWidth, CGRect titleFrame, CGRect imageFrame))completion;

@end


@interface AWEModernStickerTitleCellViewModel : NSObject

@property (nonatomic, assign, readonly) CGFloat cellWidth;

@property (nonatomic, assign, readonly) CGRect imageFrame;

@property (nonatomic, assign, readonly) CGRect titleFrame;

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, copy, readonly) NSString *title;

// 主线程发送信号
@property (nonatomic, strong, readonly) RACSignal *frameUpdateSignal;

@property (nonatomic, weak) id<AWEModernStickerTitleCellViewModelCalculateDelegate> calculateDelegate;


- (instancetype)initWithCategory:(IESCategoryModel * _Nullable)category
               calculateDelegate:(id<AWEModernStickerTitleCellViewModelCalculateDelegate>)calculateDelegate;

/// 是否对应收藏夹 cell
- (BOOL)isFavorite;

/// 根据图片 url 数量判断是否可以显示图片
- (BOOL)shouldUseIconDisplay;

- (BOOL)shouldShowYellowDot;

- (void)markAsReaded;

@end

NS_ASSUME_NONNULL_END

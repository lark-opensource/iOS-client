//
//  EMAShowImageView.h
//  Article
//
//  Created by Zhang Leonardo on 12-11-12.
//  Edited by Cao Hua from 13-10-12.
//  Edited by 武嘉晟 from 20-01-20.
//  这个12年的老代码写的不好，日后如果有需求，推荐彻底推翻使用swift重构
//

#import <UIKit/UIKit.h>
#import "ALAssetsLibrary+EMA.h"
@class EMAUIShortTapGestureRecognizer;

@protocol EMAShowImageViewProtocol;

@interface EMAShowImageView : UIView

/// 对应原图的URLRequest
@property(nonatomic, copy) NSURLRequest *largeImageURLRequest;

/** delegate，可以获得单击和双击的回调 */
@property(nonatomic, weak)id<EMAShowImageViewProtocol>delegate;


/** 拿到图片的元信息 */
@property(nonatomic, strong)UIImage * image;
@property(nonatomic, strong)ALAsset * asset;
@property(nonatomic, assign)BOOL hasImage;

/// 占位图
@property(nonatomic, strong)UIImage * placeholderImage;
@property(nonatomic, assign)CGRect placeholderSourceViewFrame;
@property(nonatomic, strong)EMAUIShortTapGestureRecognizer * tapGestureRecognizer;

// For show up animation
@property(nonatomic, assign, readonly)BOOL isDownloading;
@property(nonatomic, assign, readonly)CGFloat loadingProgress;

/// 请求头（兼容逻辑）
@property (nonatomic, strong) NSDictionary <NSString *, NSString *> *header;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame
                      success:(dispatch_block_t _Nullable)success
                      failure:(void(^ _Nullable )(NSString  * _Nullable msg))failure NS_DESIGNATED_INITIALIZER;

- (UIImageView * _Nullable)imageView;

/**
 将scrollView的Zoom设置成1
 */
- (void)resetZoom;

/**
 更新UI，如果处于缩放的话，会还原会正常状态
 */
- (void)refreshUI;

/**
 保存图片，会弹出alert进行询问
 */
- (void)saveImage;

/// 替换图片（例如原图）
/// @param largeImageURLRequest 图片请求对象
- (void)replaceLargeImageURLRequest:(NSURLRequest *)largeImageURLRequest;

// 获取触摸位置在图片中的相对位置
- (CGPoint)touchPointInImageLocation:(CGPoint)touchPoint;

@end

@protocol EMAShowImageViewProtocol<NSObject>

@optional

/**
 单次点击的回调

 @param imageView 当前正在展示的imageView
 */
- (void)showImageViewOnceTap:(EMAShowImageView *)imageView;

/**
 双击的回调

 @param imageView 当前正在展示的imageView
 */
- (void)showImageViewDoubleTap:(EMAShowImageView *)imageView;

@end

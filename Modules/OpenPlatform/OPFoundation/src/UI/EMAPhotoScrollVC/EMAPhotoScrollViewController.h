//
//  EMAPhotoScrollViewController.h
//  Article
//
//  Created by Zhang Leonardo on 12-12-4.
//  Edited by Cao Hua from 13-10-12.
//  Edited by 武嘉晟 from 20-01-20.
//  这个12年的老代码写的不好，日后如果有需求，推荐彻底推翻使用swift重构
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@protocol EMAPhotoScrollViewControllerProtocol;

@interface EMAPhotoScrollViewController : UIViewController

/** targetView 用于手势拖动提供一个放白布遮罩的view 使用前可以借鉴一下其他地方的用法*/
@property (nonatomic, weak)UIView *targetView;
/** finishBackView 用于手势拖动提供一个结束动画所在的view */
@property (nonatomic, weak)UIView *finishBackView;
/** whiteMaskViewEnable 是否需要白色遮罩 */
@property (nonatomic, assign)BOOL whiteMaskViewEnable;

@property (nonatomic, assign)BOOL shouldShowSaveOption;

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *header;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRequests:(NSArray <NSURLRequest *> * _Nonnull)reuqests
                  startWithIndex:(NSUInteger)index
               placeholderImages:(NSArray <UIImage *> * _Nullable)placeholders
                 placeholderTags:(NSArray <NSString *> * _Nullable)placeholderTags
                 originImageURLs:(NSArray <NSString *> * _Nullable)originImageURLs
                        delegate:(id <EMAPhotoScrollViewControllerProtocol> _Nullable)delegate
                         success:(dispatch_block_t _Nullable)success
                         failure:(void(^ _Nullable )(NSString  * _Nullable msg))failure NS_DESIGNATED_INITIALIZER;

/** 将VC展示出来 */
- (void)presentPhotoScrollView:(UIWindow * _Nullable)window;
- (void)dismissAnimated:(BOOL)animated completion: (void (^ __nullable)(void))completion;

@end

@protocol EMAPhotoScrollViewControllerProtocol <NSObject>

@optional
/**
 如果placeholders中找不到占位图，则从这里动态获取占位图

 @param tag placeholder标识
 @return 占位图, 没有则返回nil
 */
- (UIImage *)placeholderImageForTag:(NSString *_Nonnull)tag;

- (void)handelQRCode:(NSString * _Nonnull)qrCode fromController:(EMAPhotoScrollViewController * _Nonnull)controller;

@end

NS_ASSUME_NONNULL_END

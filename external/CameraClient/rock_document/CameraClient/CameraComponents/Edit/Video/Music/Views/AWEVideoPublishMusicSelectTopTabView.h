//
//  AWEVideoPublishMusicSelectTopTabView.h
//  Pods
//
//  Created by resober on 2019/5/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWEVideoPublishMusicSelectTopTabItemDataSelectBlock)(void);

@interface AWEVideoPublishMusicSelectTopTabItemData: NSObject

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) CGFloat underlineSpace;
@property (nonatomic, copy) AWEVideoPublishMusicSelectTopTabItemDataSelectBlock selectedBlock;

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) UIColor *titleColor;
@property (nonatomic, strong, readonly) UIColor *unselectColor;
@property (nonatomic, strong, readonly) UIFont *titleFont;
@property (nonatomic, assign) CGFloat titleTopOffset;
@property (nonatomic, assign) CGFloat buttonLeftOffset;

- (instancetype)initWithTitle:(NSString *)title;
- (instancetype)initWithTitle:(NSString *)title  isLightStyle:(BOOL)isLightStyle;

@end

typedef void(^AWEVideoPublishMusicSelectTopTabItemViewClickBlock)(AWEVideoPublishMusicSelectTopTabItemData *itemData);

@interface AWEVideoPublishMusicSelectTopTabItemView : UIView
@property (nonatomic, strong, readonly) UILabel *titleLable;
@property (nonatomic, strong, readonly) UIView *underLineView;
@property (nonatomic, copy) AWEVideoPublishMusicSelectTopTabItemViewClickBlock clickBlock;

- (instancetype)initWithItemData:(AWEVideoPublishMusicSelectTopTabItemData *)itemData NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (void)refresh;

@end

@interface AWEVideoPublishMusicSelectTopTabView : UIView

@property (nonatomic, strong, readonly) NSArray<AWEVideoPublishMusicSelectTopTabItemData *> *items;

- (instancetype)initWithItems:(NSArray<AWEVideoPublishMusicSelectTopTabItemData *> *)items NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (void)setItemClicked:(AWEVideoPublishMusicSelectTopTabItemData *)item;

@end

NS_ASSUME_NONNULL_END

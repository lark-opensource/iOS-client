//
//  AWETextToolStackView.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/16.
//

#import <UIKit/UIKit.h>
#import "AWETextStickerViewDefine.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * AWETextStackViewItemIdentity;
NS_INLINE BOOL AWETextStackViewItemIdentityEqual(AWETextStackViewItemIdentity identity1,
                                                 AWETextStackViewItemIdentity identity2) {
    return identity1 && identity2 && [identity1 isEqualToString:identity2];
}

@class AWETextStackViewItemConfig;
@protocol AWETextToolStackViewProtocol;

typedef void(^AWETextStackViewItemConfigProvider)(UIView<AWETextToolStackViewProtocol> *, AWETextStackViewItemConfig *);

typedef void(^AWETextStackViewItemClickHandler)(UIView<AWETextToolStackViewProtocol> *);

@protocol AWETextToolStackViewProtocol <NSObject>

- (void)updateAllBarItems;

- (void)updateBarItemWithItemIdentity:(AWETextStackViewItemIdentity)ItemIdentity;

- (void)registerItemConfigProvider:(AWETextStackViewItemConfigProvider)provider
                      clickHandler:(AWETextStackViewItemClickHandler)clickHandler
                   forItemIdentity:(AWETextStackViewItemIdentity)itemIdentity;

- (CGPoint)itemViewCenterOffsetWithItemIdentity:(AWETextStackViewItemIdentity)itemIdentity;

@end

@interface AWETextToolStackView : UIView <AWETextToolStackViewProtocol>

AWETextStcikerViewUsingCustomerInitOnly;

- (instancetype)initWithBarItemIdentityList:(NSArray<AWETextStackViewItemIdentity > *)itemIdentityList
                               itemViewSize:(CGSize)itemViewSize
                                itemSpacing:(CGFloat)itemSpacing NS_DESIGNATED_INITIALIZER;

@end

@interface AWETextStackViewItemConfig : NSObject

@property (nonatomic, assign) BOOL enable;
@property (nonatomic, strong) UIImage *iconImage;
@property (nonatomic, strong, nullable) NSString *title;

@end



NS_ASSUME_NONNULL_END

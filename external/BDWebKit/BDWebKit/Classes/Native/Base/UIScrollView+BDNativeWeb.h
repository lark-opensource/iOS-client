//
//  UIScrollView+BDNativeWeb.h
//  AFgzipRequestSerializer
//
//  Created by liuyunxuan on 2019/7/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDNativeScrollFrameBlock)(void);
typedef void(^BDScrollDestructAction)(void);

@interface BDNativeLifeObserverObj : NSObject


@end


@interface UIScrollView (BDNativeWeb)

@property (nonatomic) BOOL bdNativeDisableScroll;

@property (nonatomic, strong) BDNativeLifeObserverObj *bdNativeLifeObject;

@property (nonatomic, copy) BDNativeScrollFrameBlock bdNativeScrollSetFrameBlock;

- (void)bdNativeConfigScrollDestructAction:(BDScrollDestructAction)descructAction;

@end

NS_ASSUME_NONNULL_END

//
//  ACCBarItem.h
//  CameraClient
//
//  Created by Liu Deping on 2020/3/16.
//

#import <Foundation/Foundation.h>
#import "ACCBarItemCustomView.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^ACCBarItemNeedShowCustomViewBlock)(void);

typedef void (^ACCBarItemViewActionBlock)(UIView *itemView);

typedef void (^ACCBarItemViewExtraConifgBlock)(UIView *itemView);

typedef NS_ENUM(NSUInteger, ACCBarItemResourceLocation) {
    ACCBarItemResourceLocationRight = 0,
    ACCBarItemResourceLocationBottom,
};

@interface ACCBarItemResourceConfig : NSObject

@property (nonatomic, copy) NSString *imageName;

@property (nonatomic, copy) NSString *selectedImageName;

@property (nonatomic, assign) BOOL isLottie;

@property (nonatomic, copy) NSString *lottieResourceName;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, assign) void *itemId;

@property (nonatomic, assign) ACCBarItemResourceLocation location;

@end


@interface ACCBarItem<T> : NSObject

- (instancetype)initWithConfig:(ACCBarItemResourceConfig *)config;

- (instancetype)initWithImageName:(NSString *)imageName itemId:(void *)itemId;

- (instancetype)initWithImageName:(NSString *)imageName title:(NSString *)title itemId:(void *)itemId;

- (instancetype)initWithCustomView:(UIView<ACCBarItemCustomView> *)customView itemId:(void *)itemId;

@property (nonatomic, strong) UIView<ACCBarItemCustomView> *customView; // default is nil;

@property (nonatomic, assign) BOOL useAnimatedButton;

@property (nonatomic, assign) BOOL placeLastUnfold;

@property (nonatomic, copy) NSString *imageName;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *selectedImageName;

@property (nonatomic, assign) void *itemId;

@property (nonatomic, assign) ACCBarItemResourceLocation location;

@property (nonatomic, copy) ACCBarItemViewActionBlock barItemActionBlock;

@property (nonatomic, copy) ACCBarItemViewExtraConifgBlock barItemViewConfigBlock;

@property (nonatomic, copy) ACCBarItemNeedShowCustomViewBlock needShowBlock;

@property (nonatomic, strong) T extraData;

- (void)addTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END

//
//  DVELoadingView.h
//  NLEEditor
//
//  Created by bytedance on 2021/6/9.
//

#import <UIKit/UIKit.h>
#import "DVEPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELoadingType : NSObject

@property (nonatomic, copy) NSString *rawValue;

- (instancetype)initWithRawValue:(NSString *)rawValue;

+ (instancetype)smallLoadingType;

+ (instancetype)largeLoadingType;

+ (instancetype)lightSmallLoadingType;

+ (instancetype)lightLargeLoadingType;


@end

@interface DVELoadingView : UIView<DVEPickerEffectOverlayProtocol>


- (void)setLottieLoadingWithType:(DVELoadingType *)type;

- (void)startLottieLoadingWithType:(DVELoadingType *)type loopAnimation:(BOOL)loopAnimation;

- (void)startLoadingWithImage:(UIImage * _Nullable)image;

- (void)stopLoading;

@end

NS_ASSUME_NONNULL_END

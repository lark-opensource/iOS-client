//
//  ACCAnimatedDateStickerController.h
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2021/3/18.
//

#import <Foundation/Foundation.h>

@class IESEffectModel, AWEVideoPublishViewModel;

typedef NS_ENUM(NSInteger, ACCAnimatedDateStickerDateFormattingStyle) {
    ACCAnimatedDateStickerDateFormattingStyleYearMonthDay = 0,
    ACCAnimatedDateStickerDateFormattingStyleHourMinute = 1,
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCAnimatedDateStickerViewModel : NSObject

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;

@property (nonatomic, assign, readonly) BOOL triedFetchingBefore;

- (void)fetchStickerWithCompletion:(void (^)(IESEffectModel * _Nullable sticker, NSString * _Nullable stickerPath, NSString * _Nullable animationPath, NSError * _Nullable error))completion;

- (BOOL)shouldAddAnimatedDateSticker;

- (NSDate *)usedDate;

- (ACCAnimatedDateStickerDateFormattingStyle)dateFormattingStyle;

@end

NS_ASSUME_NONNULL_END

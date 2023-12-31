//
//  AWEEmojiStickerDataManager.h
//  CameraClient
//
//  Created by HuangHongsen on 2020/2/6.
//

#import <Foundation/Foundation.h>
#import "ACCStickerPannelLogger.h"

NS_ASSUME_NONNULL_BEGIN

@class IESCategoryModel;
@class IESEffectModel;

@interface AWEEmojiStickerDataManager : NSObject

// 表情面板 emoji-ios
@property (nonatomic, copy, readonly) NSArray<IESCategoryModel *> *emojiCategories;
@property (nonatomic, copy, readonly) NSArray<IESEffectModel *> *emojiEffects;
@property (nonatomic, assign, readonly) BOOL emojiHasMore;
@property (nonatomic, assign, readonly) NSInteger emojiCursor;
@property (nonatomic, assign, readonly) NSInteger emojiSortingPosition;
@property (nonatomic, copy) NSString *requestID;
@property (nonatomic, copy) NSDictionary *trackExtraDic;
@property (nonatomic, weak) id<ACCStickerPannelLogger> logger;

+ (instancetype)defaultManager;

- (void)downloadEmojisWithCompletion:(void(^)(BOOL downloadSuccess))completion;

// 支持emoji分页
- (void)fetchEmojiPanelCategoriesAndDefaultEffects:(void(^)(BOOL downloadSuccess))completion;
- (void)loadMoreEmojisWithCompletion:(void(^)(BOOL downloadSuccess))completion;
@end

NS_ASSUME_NONNULL_END

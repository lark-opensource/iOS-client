//
//  ACCSocialStickerEditToolbar.h
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/6.
//

#import <UIKit/UIKit.h>
#import "ACCSocialStickerCommDefines.h"
#import "ACCSocialStickerModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCSocialStickerEditToolbar : UIView

ACCSocialStickerViewUsingCustomerInitOnly;
- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel;

@property (nonatomic, copy) NSDictionary *trackInfo;

@property (nonatomic, assign, readwrite) ACCSocialStickerType stickerType; // resettable

@property (nonatomic, copy) void (^onSelectMention)(ACCSocialStickeMentionBindingModel *mentionBindingData);
@property (nonatomic, copy) void (^onSelectHashTag)(ACCSocialStickeHashTagBindingModel *hashTagBindingData);

- (void)searchWithKeyword:(NSString *_Nullable)keyword;
- (void)cancelSearch;

- (void)updateSelectedMention:(ACCSocialStickeMentionBindingModel *_Nullable)mentionBindingData;

+ (CGFloat)defaulBarHeight;

@end

NS_ASSUME_NONNULL_END

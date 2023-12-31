//
//  ACCTextStickerInputController.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/9.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCTextStickerExtraModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCTextStickerInputControllerDelegate;

@interface ACCTextStickerInputController : NSObject

- (instancetype)initWithTextView:(UITextView *)textView
               initialExtraInfos:(NSArray<ACCTextStickerExtraModel *> *_Nullable)extraInfos;

@property (nonatomic, weak) id<ACCTextStickerInputControllerDelegate> delegate;

#pragma mark - textView delegate association
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)textViewDidChangeSelection:(UITextView *)textView;

#pragma mark - config
@property (nonatomic, assign) NSInteger maxHashtagCount;
@property (nonatomic, assign) NSInteger maxMentionCount;

@property (nonatomic, copy, readonly) NSArray<ACCTextStickerExtraModel *> *_Nullable extraInfos;

- (NSInteger)numberOfExtrasForType:(ACCTextStickerExtraType)extraType;

#pragma mark - append entrance
- (void)appendExtraCharacterWithType:(ACCTextStickerExtraType)extraType;
- (void)appendTextExtraWithExtra:(ACCTextStickerExtraModel *)extra;

- (void)updateSearchKeywordStatus;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@protocol ACCTextStickerInputControllerDelegate <NSObject>

@optional

/// 更新搜索
/// @param shouldSearch 是否需要展示搜索面板
/// @param keyword 搜索词
/// @param searchType 搜索类型 mention / hashtag
- (void)textStickerInputController:(ACCTextStickerInputController *)controller
             didUpdateSearchStatus:(BOOL)shouldSearch
                           Keyword:(NSString *_Nullable)keyword
                        searchType:(ACCTextStickerExtraType)searchType;

- (void)textStickerInputController:(ACCTextStickerInputController *)controller
             onExtraInfoDidChanged:(NSArray<ACCTextStickerExtraModel *> *_Nullable)currentExtraInfo;

- (void)textStickerInputController:(ACCTextStickerInputController *)controller
                     onReplaceText:(NSString *)text
                         withRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END

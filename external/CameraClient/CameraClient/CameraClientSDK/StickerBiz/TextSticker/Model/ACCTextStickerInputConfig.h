//
//  ACCTextStickerRecommendInputController.h.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCTextStickerRecommendItem;

@interface ACCTextStickerRecommendInputConfig : NSObject<NSCopying>

@property (nonatomic, strong) NSMutableArray<NSString *> *cachedTitles;
@property (nonatomic, assign) NSUInteger lastTotalLength;// 之前的总长度
@property (nonatomic, assign) NSUInteger lastInputStart;// 上一次选择输入开始位置
@property (nonatomic, assign) BOOL hasManulInput;// 是否有手工输入
@property (nonatomic, assign) NSRange lastRecommendRange;// 上一次推荐值的range

@property (nonatomic, assign) BOOL disableSearch;
@property (nonatomic, copy) NSString *lastSearchKey;// 上一次搜索的值

- (NSString *)currentSearchKey;

@end

NS_ASSUME_NONNULL_END

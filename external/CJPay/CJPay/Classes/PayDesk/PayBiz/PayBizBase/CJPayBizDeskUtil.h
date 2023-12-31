//
//  CJPayBizDeskUtil.h
//  Aweme
//
//  Created by shanghuaijun on 2023/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayChannelBizModel;
@class CJPayZoneSplitInfoModel;
@interface CJPayBizDeskUtil : NSObject

+ (NSArray<CJPayChannelBizModel *> *)reorderDisableCardsWithMethodArray:(NSArray<CJPayChannelBizModel *> *)array
                                                     zoneSplitInfoModel:(CJPayZoneSplitInfoModel *)zoneSplitInfoModel;

@end

NS_ASSUME_NONNULL_END

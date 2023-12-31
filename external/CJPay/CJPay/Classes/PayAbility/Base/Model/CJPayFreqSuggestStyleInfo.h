//
//  CJPayFreqSuggestStyleInfo.h
//  sandbox
//
//  Created by xutianxi on 2023/5/24.
//

#import <UIKit/UIKit.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFreqSuggestStyleInfo : JSONModel

@property (nonatomic, assign) BOOL hasSuggestCard;
@property (nonatomic, copy) NSString *titleButtonLabel;
@property (nonatomic, copy) NSString *tradeConfirmButtonLabel;
@property (nonatomic, copy) NSArray <NSNumber*> *freqSuggestStyleIndexList;

@end

NS_ASSUME_NONNULL_END

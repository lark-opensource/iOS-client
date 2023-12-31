//
//  CJPaySubPayTypeIconTipModel.h
//  Pods
//
//  Created by bytedance on 2021/6/25.
//

#import <JSONModel/JSONModel.h>
#import "CJPaySubPayTypeIconTipInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPaySubPayTypeIconTipInfoModel;

@interface CJPaySubPayTypeIconTipModel : JSONModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<CJPaySubPayTypeIconTipInfoModel> *contentList;

@end

NS_ASSUME_NONNULL_END

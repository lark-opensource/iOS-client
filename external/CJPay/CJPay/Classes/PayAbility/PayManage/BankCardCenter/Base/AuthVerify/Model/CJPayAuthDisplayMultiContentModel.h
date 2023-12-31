//
//  CJPayAuthDisplayMultiContentModel.h
//  Pods
//
//  Created by 易培淮 on 2020/8/7.
//

#import <JSONModel/JSONModel.h>
#import "CJPayAuthDisplayContentModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayAuthDisplayContentModel;
@interface CJPayAuthDisplayMultiContentModel : JSONModel

@property (nonatomic, copy) NSString *oneDisplayDesc;
@property (nonatomic, copy) NSArray<CJPayAuthDisplayContentModel> *secondDisplayContents;

@end

NS_ASSUME_NONNULL_END


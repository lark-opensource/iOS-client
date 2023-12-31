//
//  CJPaySignCardInfo.h
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/7/26.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySignCardInfo : JSONModel

@property (nonatomic, copy) NSString *titleMsg;
@property (nonatomic, copy) NSString *buttonText;

@end

NS_ASSUME_NONNULL_END

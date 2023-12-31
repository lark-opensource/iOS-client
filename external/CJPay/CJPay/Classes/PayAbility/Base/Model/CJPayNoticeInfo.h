//
//  CJPayNoticeInfo.h
//  CJPay
//
//  Created by 王新华 on 10/9/19.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNoticeInfo : JSONModel

@property (nonatomic, copy) NSString *noticeType;
@property (nonatomic, copy) NSString *notice;
@property (nonatomic, copy) NSString *withdrawBtnStatus; //提现按钮状态 1:可点击  0（非1）：不可点击;只有为"0"的时候，才置灰！！！切记; 为空的""，默认可点击！！

@end

NS_ASSUME_NONNULL_END

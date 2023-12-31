//
//  CJPayIAPConfigResponse.h
//  Aweme
//
//  Created by bytedance on 2022/12/16.
//

#import "CJPayBaseResponse.h"
#import <JSONModel/JSONModel.h>
#import "CJPayIAPFailPopupConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIAPConfigResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *failPopupConfig;

- (CJPayIAPFailPopupConfigModel *)failPopupConfigModel;

@end

NS_ASSUME_NONNULL_END

//
//  CJPayTypeInfo+Util.h
//  Pods
//
//  Created by wangxinhua on 2020/9/10.
//

#import <Foundation/Foundation.h>
#import "CJPayTypeInfo.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayTypeInfo(Util)

- (NSArray<CJPayDefaultChannelShowConfig *> *)showConfigForHomePageWithId:(NSString *)identify;
- (NSArray <CJPayDefaultChannelShowConfig *> *)showConfigForCardList;
- (NSArray<CJPayDefaultChannelShowConfig *> *)showConfigForUniteSign;

@end

@interface CJPayIntegratedChannelModel(CJPay)

- (NSArray <CJPayDefaultChannelShowConfig *> *)buildConfigsWithIdentify:(NSString *)identify;

@end

@interface CJPayChannelModel(CJPayRequestParamProtocol)

- (NSDictionary *)buildParams;

@end

NS_ASSUME_NONNULL_END

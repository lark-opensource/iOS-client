//
//  CJPayDyPayMethodCellViewModel.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/23.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseListViewModel.h"
#import "CJPayLoadingManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayDefaultChannelShowConfig;

typedef void (^CJPayDyPayMethodCellDidSelectedBlock)(CJPayDefaultChannelShowConfig *);

@interface CJPayDyPayMethodCellViewModel : CJPayBaseListViewModel<CJPayBaseLoadingProtocol>

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *showConfig;
@property (nonatomic, assign) BOOL needAddTopLine;
@property (nonatomic, strong) CJPayDyPayMethodCellDidSelectedBlock didSelectedBlock;
@property (nonatomic, assign) BOOL isDeduct; // 是否是轮扣样式的切卡页

@end

NS_ASSUME_NONNULL_END

//
//  CJPayMehtodDataUpdateProtocol.h
//  CJPay
//
//  Created by 王新华 on 9/3/19.
//

#ifndef CJPayMehtodDataUpdateProtocol_h
#define CJPayMehtodDataUpdateProtocol_h

#import "CJPayChannelBizModel.h"
#import "CJPayDefaultChannelShowConfig.h"
typedef NS_ENUM(NSUInteger, CJPayMethodCellType) {
    CJPayMethodCellTypeSingle,
    CJPayMethodCellTypeMulti,
};

@protocol CJPayMethodDataUpdateProtocol <NSObject>

- (void)updateContent:(CJPayChannelBizModel *)data;

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data;

@optional

@end

#endif /* CJPayMehtodDataUpdateProtocol_h */

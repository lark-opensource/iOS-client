//
// Created by 张海阳 on 2019/10/20.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseResponse.h"
#import <JSONModel/JSONModel.h>

@class CJPayErrorButtonInfo;
@protocol CJPayErrorButtonInfo;


@interface CJPayPassKitBaseResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

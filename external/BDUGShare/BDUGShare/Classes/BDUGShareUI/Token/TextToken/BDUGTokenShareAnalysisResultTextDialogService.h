//
//  BDUGTokenAnalysisResultTextDialogService.h
//  Article
//
//  Created by zengzhihui on 2018/5/31.
//

#import <Foundation/Foundation.h>
#import "BDUGTokenShareAnalysisResultCommom.h"

@class BDUGTokenShareAnalysisResultModel;
@class BDUGTokenShareServiceActionModel;

/*
 * App进前台口令解析纯文本弹窗，各个业务自己适配
 */
@interface BDUGTokenShareAnalysisResultTextDialogService : NSObject

+ (void)showTokenAnalysisDialog:(BDUGTokenShareAnalysisResultModel *)resultModel
                    buttonColor:(UIColor *)buttonColor
                 actionModel:(BDUGTokenShareServiceActionModel *)actionModel;

@end

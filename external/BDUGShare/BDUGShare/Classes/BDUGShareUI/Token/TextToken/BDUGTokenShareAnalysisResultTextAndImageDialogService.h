//
//  BDUGTokenShareAnalysisResultTextAndImageDialogService.h
//  Article
//
//  Created by zengzhihui on 2018/6/1.
//

#import <Foundation/Foundation.h>
#import "BDUGTokenShareAnalysisResultCommom.h"

@class BDUGTokenShareAnalysisResultModel;
@class BDUGTokenShareServiceActionModel;

/*
 * App进前台口令解析图文弹窗，各个业务自己适配
 */
@interface BDUGTokenShareAnalysisResultTextAndImageDialogService : NSObject

+ (void)showTokenAnalysisDialog:(BDUGTokenShareAnalysisResultModel *)resultModel
                    buttonColor:(UIColor *)buttonColor
                    actionModel:(BDUGTokenShareServiceActionModel *)actionModel;


@end

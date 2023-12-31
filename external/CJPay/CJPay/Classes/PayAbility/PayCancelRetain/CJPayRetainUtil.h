//
//  CJPayRetainUtil.h
//  Pods
//
//  Created by 王新华 on 2021/8/11.
//

#import <Foundation/Foundation.h>
#import "CJPayRetainUtilModel.h"


NS_ASSUME_NONNULL_BEGIN

@interface CJPayRetainUtil : NSObject

+ (BOOL)couldShowRetainVCWithSourceVC:(UIViewController *)sourceVC
                      retainUtilModel:(CJPayRetainUtilModel *)retainUtilModel;

+ (BOOL)couldShowRetainVCWithSourceVC:(UIViewController *)sourceVC
                      retainUtilModel:(CJPayRetainUtilModel *)retainUtilModel
                           completion:(void (^ __nullable)(BOOL success))completion;

+ (BOOL)couldShowLynxRetainVCWithSourceVC:(UIViewController *)sourceVC
                          retainUtilModel:(CJPayRetainUtilModel *)retainUtilModel
                               completion:(void (^__nullable)(BOOL success))completion;
            
+ (BOOL)needShowRetainPage:(CJPayRetainUtilModel *)retainUtilModel; //仅判断是否需要展示挽留

// 兜底schema，避免取不到schema, 目前只应用在O项目流程以及验密组件。聚合收银台首页不是用这个兜底schema
+ (NSString *)defaultLynxRetainSchema;
@end

NS_ASSUME_NONNULL_END

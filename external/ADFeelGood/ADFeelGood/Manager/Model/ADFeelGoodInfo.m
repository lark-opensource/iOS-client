//
//  ADFeelGoodInfo.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/2/1.
//

#import "ADFeelGoodInfo.h"

@interface ADFeelGoodInfo ()

#pragma mark - public
/// Event taskid
@property (nonatomic, copy, nullable) NSString *taskID;
/// triggerEvent返回的数据
@property (nonatomic, strong, nullable) NSDictionary *triggerResult;
/// 是否为全局弹框
@property (nonatomic, assign, getter=isGlobalDialog) BOOL globalDialog;

@end

@implementation ADFeelGoodInfo

+ (ADFeelGoodInfo *)createInfoModel:(NSString *)taskID
                      triggerResult:(nullable NSDictionary *)triggerResult
                       globalDialog:(BOOL)globalDialog
{
    ADFeelGoodInfo *infoModel = nil;
    infoModel = [[ADFeelGoodInfo alloc] init];
    
    infoModel.taskID = taskID;
    infoModel.triggerResult = triggerResult;
    infoModel.globalDialog = globalDialog;
    
    return infoModel;
}

@end

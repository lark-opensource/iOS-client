//
//  BDABTestExperimentCache.h
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDABTestManager.h"

/**
 通过读写NSUserDefaults，存储common接口下发的内容和用户手动修改的结果。
 */
@class BDABTestExperimentItemModel;

extern NSString * const kBDABTestResultUpdatedNotificaion;

@interface BDABTestManager (Cache)

/**
 存储网络请求获得的json数据（common接口）

 @param jsonData 已经经过合法性校验的json数据
 格式如下：
 {
     "key1":  {"val": "实验值", "vid": "实验分组的id"},
     "key2":  {"val": "实验值", "vid": "实验分组的id"}
 }
 */
- (void)saveFetchedJsonData:(NSDictionary<NSString *, NSDictionary *> *)jsonData;

/**
 存储用户手动修改的结果
 
 @param key 用户手动修改的key
 @param value 用户手动修改后的值
 @param vid 这个实验的vid
 */
- (void)editExperimentWithKey:(NSString *)key value:(id)value vid:(NSNumber *)vid;

/**
 key对应的实验结果，会merge网络请求结果和手动修改结果
 */
- (BDABTestExperimentItemModel *)savedItemForKey:(NSString *)key;

/**
 获取某个key被用户修改的结果，和网络请求结果无关
 */
- (BDABTestExperimentItemModel *)editedItemForKey:(NSString *)key;

/**
 获取目前有效的vid。如果一个vid不在common接口下发的列表里，则认为无效。
 */
- (NSSet<NSString *> *)validVids;

@end

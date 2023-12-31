//
//  HMDBGFMDBConfig.h
//  HMDBGFMDB
//
//  Created by biao on 2017/7/19.
//  Copyright © 2017年 Biao. All rights reserved.
//

#ifndef HMDBGFMDBConfig_h
#define HMDBGFMDBConfig_h

#define hmdbg_primaryKey @"localID"

//keyPath查询用的关系，hmdbg_equal:等于的关系；hmdbg_contains：包含的关系.
#define hmdbg_equal @"Relation_Equal"
#define hmdbg_contains @"Relation_Contains"

#define hmdbg_complete_B void(^_Nullable)(BOOL isSuccess)
#define hmdbg_complete_I void(^_Nullable)(bg_dealState result)
#define hmdbg_complete_A void(^_Nullable)(NSArray* _Nullable array)
#define hmdbg_changeBlock void(^_Nullable)(bg_changeState result)

typedef NS_ENUM(NSInteger,bg_changeState){//数据改变状态
    bg_insert,//插入
    bg_update,//更新
    bg_delete,//删除
    bg_drop//删表
};

typedef NS_ENUM(NSInteger,bg_dealState){//处理状态
    bg_error = -1,//处理失败
    bg_incomplete = 0,//处理不完整
    bg_complete = 1//处理完整
};

typedef NS_ENUM(NSInteger,bg_sqliteMethodType){//sqlite数据库原生方法枚举
    bg_min,//求最小值
    bg_max,//求最大值
    bg_sum,//求总和值
    bg_avg//求平均值
};

typedef NS_ENUM(NSInteger,bg_dataTimeType){
    bg_createTime,//存储时间
    bg_updateTime,//更新时间
};

/**
 封装处理传入数据库的key和value.
 */
extern NSString* _Nonnull hmdbg_sqlKey(NSString* _Nonnull key);
/**
 转换OC对象成数据库数据.
 */
extern NSString* _Nonnull hmdbg_sqlValue(id _Nonnull value);
/**
 根据keyPath和Value的数组, 封装成数据库语句，来操作库.
 */
extern NSString* _Nonnull hmdbg_keyPathValues(NSArray* _Nonnull keyPathValues);
/**
 清除缓存
 */
extern void hmdbg_cleanCache(void);

#endif /* HMDBGFMDBConfig_h */

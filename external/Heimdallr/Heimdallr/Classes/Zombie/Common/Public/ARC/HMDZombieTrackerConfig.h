//
//  HMDZombieTrackerConfig.h
//  AFgzipRequestSerializer
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDModuleConfig.h"

extern NSString * _Nullable const kHMDModuleZombieDetector;//野指针监控

@interface HMDZombieTrackerConfig : HMDModuleConfig

/* 监控CF对象，默认NO，无法热生效，需重启监控;
 由于现有监控CF对象，可能触发崩溃，这里仅在debug环境生效，release环境失效！！！
 */
@property(nonatomic, assign) BOOL monitorCFObj;

/**
 配置类名，如果配置了，那就捕获这个zombie时候，也保存这个对象调用dealloc的堆栈（最多保存100个zombieObject的堆栈），上传到slardar；
 谨慎配置，会增大开销，只有线上捕获到zombie，然后也不知道在什么时机调用了dealloc，才配置；否则不要配置
 */
@property(nonatomic, strong, nullable) NSArray<NSString *> *classList;

/**
 配置类名，如果配置了，那就只监控这些类是否发生了zombie，减少性能消耗。默认为空，监控所有的类是否发生了zombie
 */
@property(nonatomic, strong, nullable) NSArray<NSString *> *monitorClassList;

// 保存最多的zombie dealloc堆栈数量，默认100个；谨慎配置
@property(nonatomic, assign) NSInteger maxZombieDeallocCount;

@end


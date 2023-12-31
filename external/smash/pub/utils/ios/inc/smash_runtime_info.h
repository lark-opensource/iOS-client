#ifndef __smash_util_smash_runtime_info_h__
#define __smash_util_smash_runtime_info_h__

/**
 * @brief 存储不同算法运行时内存和耗时等数据,作为调用方调度的一个工具
 *
 **/
typedef struct ModuleRunTimeInfo{
  float memory_consumption;   ///< 算法运行时内存消耗，单位 Mb
  float time_consumption;     ///< 算法运行耗时,单位ms
  unsigned int module_level;  ///< 算法优先级1-->5,
  char extra_info[50];        ///< 其他信息返回,保留字段,目前未使用
}ModuleRunTimeInfo;

#endif

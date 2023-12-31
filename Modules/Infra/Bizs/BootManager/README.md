# BootManager

设计文档：https://bytedance.feishu.cn/docs/doccnGESllyodXuOt3BRbl3dvzb#8wnGnp
GuideBook：https://bytedance.feishu.cn/docs/doccnqpCwl2vEKswCyVbcb1dVqh#

## 组件作用


## 使用方法
```
Step1: 业务Task逻辑
/*
 1.继承自LaunchTask
 2.根据任务类型，选择协议「Flowable、Asyncable、Branchable」，见：「Task协议」
*/
class SetupLoggerTask: LaunchTask, Flowable {
    // 唯一标识，用Task类名即可，要和BootConfigs中的配置完全一致才会被调用
    static var identify = "SetupLoggerTask"
}


Step2: 注册Task
class Assembly {
    // 注册Task
    BootManager.registry(SetupLoggerTask.self)
}


Step3: BootConfigs.Plist声明执行Stage
Value为 {SetupLoggerTask.identify}
```

## Author

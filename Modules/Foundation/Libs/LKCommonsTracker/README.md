# LKCommonsTracker

## 组件作用
轻量级的使用 slardar 埋点服务, 使用前需要添加配置, 在 allow\_log\_type 配置 "service\_monitor": 1000000，并且在 allow\_service\_name 中配置 trackService Name 为 1000000
在 [slardar](https://slardar.bytedance.net/) 平台可以查询上传数据, 事件列表中不是实时数据, 如果需要实时数据 可以通过单点追查功能查询

[文档](https://slardar.bytedance.net/help/ios/eventList.html#%E4%BA%8B%E4%BB%B6%E5%9F%8B%E7%82%B9%E6%94%AF%E6%8C%81%E7%9A%84%E6%8E%A5%E5%8F%A3)
## 使用方法
~~~swift
public protocol TrackerService {
    /**
    *  监控某个service的值，并上报
    *
    *  @param serviceName NSString 类型的名称
    *  @param metric      字典必须是key-value形式，而且只有一级，是数值类型的信息，对应 Slardar 的 metric
    *  @param category    字典必须是key-value形式，而且只有一级，是维度信息，对应 Slardar 的 category
    *  @param extraValue  额外信息，方便追查问题使用，Slardar 平台不会进行展示，hive 中可以查询
    */
    func track(service: String, metric: [AnyHashable: Any], category: [AnyHashable: Any], extra: [AnyHashable: Any])

    /**
     *  监控某个service的值，并上报
     *
     *  @param serviceName String 类型的名称
     *  @param value       是一个id类型的，可以传一个number，string，字典， 字典必须是key-value形式
     *  @param extraValue  额外信息，方便追查问题使用
     */
    func track(service: String, value: Any, extra: [String: String])

    /**
     *  监控某个 service的状态，并上报
     *
     *  @param serviceName String 类型的名称
     *  @param status      是一个int类型的值，可枚举的几种状态
     *  @param extraValue  额外信息，方便追查使用
     */
    func track(service: String, status: Int, extra: [String: String])

    /**
     *  上报某种自定义 log type 数据
     *
     *  @param data 上报的数据
     */
    func track(data: [String: AnyObject], logType: String)
}
~~~
Monitor 由宿主程序调用 setup 方法注册具体上传实现, 其他使用模块直接使用即可

# 使用

1. 在 apmevent_config.json文件内输入对应的event配置。
示例：
{
    "Events": [
        {
            "Key": "mail_message_image_load",
            "Scene": "MailRead",
            "Page": "message",
            "LatencyDetails": {
                "lantencyDetailKey": "String",
                "lantencyDetailKeyB": "Int",
                "lantencyDetailKeyC": ["select_thread", "swipe_thread", "notification"]
            },
            "Metrics": {
                "metricsKeyA": "String",
                "metricsKeyB": "Int"
            },
            "Category": {
                "scene": ["select_thread", "swipe_thread", "notification"],
                "from_db": "Int",
                "single_const": ["const"]
            }
        },
        {
            "Key": "mail_draft_have_fun",
            "Scene": "MailDraft",
            "Page": "funny",
            "LatencyDetails": {},
            "Metrics": {},
            "Category": {
                "scene": ["select_thread", "swipe_thread", "notification"],
                "from_db": "Int",
                "single_const": ["const"]
            }
        }
    ]
}

2. 执行 mail-ios-client/Scripts/apmevent_creator.rb ，例如: ruby ./Scripts/apmevent_creator.rb

3. 拷贝 Script/dist/result.swift 文件夹内生成的类至 MailAPMEvent.swift or MailAPMEvent+XXX.swift (如果想做划分，可以自己加扩展)
( 如果发现编不过，有新增Scene，请直接联系 @liutefeng. 因为Scene的定义在其他Pod组件，不在MailSDK内 )

4. 业务代码使用生成的Event实例做调用，可以参考其他可感知错误埋点

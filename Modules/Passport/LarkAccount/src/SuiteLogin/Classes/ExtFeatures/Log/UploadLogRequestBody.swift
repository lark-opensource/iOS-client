//
// Created by Yiming Qu on 2019-06-25.
//

import Foundation

func toJSONString<T: Codable>(_ model: T) -> String {
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(model)
        let JSONString = String(data: data, encoding: String.Encoding.utf8)
        return JSONString ?? "{}"
    } catch _ {
        return "{}"
    }
}

class HeaderModel {
    /**
     * device_id : 43891908782
     * device_model : Android_Xiaomi
     * display_name : Lark
     * os_version : 3.1.0
     * aid : 1161
     * os : macos
     * sdk_version : 2.9.4
     * tenant_id : 1
     * version : 2.9.5
     */

    // 设备 id：如 43891908782
    var device_id: String
    // 机型，如 HuaWei，mac
    var device_model: String = UIDevice.current.lu.modelName()
    // 应用名，从Info.plist获取 Lark、Feishu
    var display_name: String
    // android os 版本号
    var os_version: String = UIDevice.current.systemVersion
    // 用户id（rust sdk 未加密）
    var user_id: String
    // appId 从Info.plist获取
    var aid: String
    // 系统：macos，iOS，Android。写死 Android
    var os: String = UIDevice.current.systemName
    // Rust SDK 版本
    var sdk_version: String = "3.3.3"
    // 租户 id，登录前若没有则为空
    var tenant_id: String
    // 应用版本，如 3.3.0
    var version: String

    init(deviceId: String, userId: String, tenantId: String, appVersion: String, displayName: String, aid: String) {
        self.device_id = deviceId
        self.user_id = userId
        self.tenant_id = tenantId
        self.version = appVersion
        self.display_name = displayName
        self.aid = aid
    }

    func dict() -> [String: Any] {
        return [
            "device_id": device_id,
            "device_model": device_model,
            "display_name": display_name,
            "os_version": os_version,
            "user_id": user_id,
            "aid": aid,
            "os": os,
            "sdk_version": sdk_version,
            "tenant_id": tenant_id,
            "version": version
        ]
    }
}

class DataModel {
    /**
     * data : {"message":"fetch: channel= CronetQuic domain= \"internal-api-lark-api-hl.feishu.cn\" ip= Some(\"119.249.48.237\") cmd= 0 code= 200 cost= 44 protocol= Some(\"quic\")  c_point=\"0de343248e1f48aa3e430bf3b6b28e34fe79e254\"  req_id= \"ABCDEFD-ABGESET\"","target":"lib_net::client::fetch::helpers","time":"2019-06-20T21:42:28.732151+08:00","module_path":"lib_net::client::fetch::helpers","pid":20857,"thread":"t:worker-12","file":"lib-net/src/client/fetch/helpers.rs","level":"INFO","line":355}
     * log_type : rust_sdk_log
     */

    // 业务数据，DataDataModel 类型的 json 字符串
    var data: String
    // 日志类型，写死 "rust_sdk_log"
    var log_type: String = "rust_sdk_log"

    init(data: String) {
        self.data = data
    }

    func dict() -> [String: Any] {
        return [
            "data": data,
            "log_type": log_type
        ]
    }
}

class DataDataModel: Codable {
    /**
     * message : fetch: channel= CronetQuic domain= "internal-api-lark-api-hl.feishu.cn" ip= Some("119.249.48.237") cmd= 0 code= 200 cost= 44 protocol= Some("quic") c_point="0de343248e1f48aa3e430bf3b6b28e34fe79e254"  req_id= "ABCDEFD-ABGESET"
     * target : lib_net::client::fetch::helpers
     * time : 2019-06-20T21:42:28.732151+08:00
     * module_path : lib_net::client::fetch::helpers
     * pid : 20857
     * thread : t:worker-12
     * file : lib-net/src/client/fetch/helpers.rs
     * level : INFO
     * line : 355
     */

    // 见 data.data.message 协议
    var message: String
    /// 工程模块名，Android signinsdk 模块日志为 "framework:signinsdk"； iOS 为 "SuiteLogin"
    /// rustsdk 含义：target 是 rust 的命令对象
    var target: String = "SuiteLogin"
    /// 日志时间，格式见示例
    var time: String
    /// 工程模块名，signinsdk 模块日志为 "framework:signinsdk"; iOS 为 "SuiteLogin"
    /// rustsdk 含义：module 是 rust 的模块，
    var module_path: String = "SuiteLogin"
    /// 写死 lark_login_log
    var module: String = "lark_login_log"
    // processId
    var pid: Int = 0
    // 线程名
    var thread: String
    /// 当前日志触发的文件
    var file: String
    /// 日志级别：   "EMERG":   0,
    ///            "PANIC":   0,
    ///            "ALERT":   1,
    ///            "CRIT":    2,
    ///            "ERR":     3,
    ///            "ERROR":   3,
    ///            "WARNING": 4,
    ///            "WARN":    4,
    ///            "NOTICE":  5,
    ///            "INFO":    6,
    ///            "DEBUG":   7,
    ///            "TRACE":   7,
    /// 同 https://en.wikipedia.org/wiki/Syslog#Severity_level
    var level: String
    // 调用日志的代码行数
    var line: Int

    init(message: String, time: String, thread: String, file: String, level: String, line: Int) {
        self.message = message
        self.time = time
        self.thread = thread
        self.file = file
        self.level = level
        self.line = line
    }

    func JSONString() -> String {
        return toJSONString(self)
    }
}

// ${seq_id}: ${BUSINESS_MESSAGE} c_point=0de343248e1f48aa3e430bf3b6b28e34fe79e254 cp_id=aaaa rid=${rid} env=release redirect=true network=wifi aos_process_name=main h5_log=true trace_id=${TRACE_ID}
class Message: Codable {
    // 业务日志
    var business_msg: String
    // 加密之后的 CONTACT_POINT。若无，则无 c_point 字段
    var c_point: String
    // 由 device_id 和 c_point 公共计算得到，不同 device_id 或 c_point 要保证唯一性
    var trace_id: String
    // 当前环境，staging | prelease | release | overseastaging | oversea
    var env: String
    // 是否发生环境重置
    var redirect: Bool = false
    // wifi | 4G | 3G | 2G
    var network: String
    // 是否 h5 日志
    var h5_log: Bool
    // contact point id
    var cp_id: String
    /// 日志序号
    var seq_id: Int64
    /// real device_id
    var rid: String
    /// app install_id
    var install_id: String
    /// 序列化分割
    static let split: String = " "
    /// 序列化键值分割
    static let kvSplit: String = "="

    init(
        businessMsg: String,
        cPoint: String,
        traceId: String,
        env: String,
        redirect: Bool,
        network: String,
        h5Log: Bool,
        cpId: String,
        seqId: Int64,
        rid: String,
        installId: String
    ) {
        self.business_msg = businessMsg
        self.c_point = cPoint
        self.trace_id = traceId
        self.env = env
        self.redirect = redirect
        self.network = network
        self.h5_log = h5Log
        self.cp_id = cpId
        self.seq_id = seqId
        self.rid = rid
        self.install_id = installId
    }

    func serialize() -> String {
        func component(_ k: String, _ v: Any) -> String {
            return "\(k)\(Message.kvSplit)\(v)\(Message.split)"
        }
        var output = "\(seq_id): "
        output += "\(business_msg)\(Message.split)"
        if !c_point.isEmpty {
            output += component("c_point", c_point)
        }
        if !cp_id.isEmpty {
            output += component("cp_id", cp_id)
        }
        if !rid.isEmpty {
            output += component("rid", rid)
        }
        output += component("env", env)
        if redirect {
            output += component("redirect", redirect)
        }
        output += component("network", network)
        if h5_log {
            output += component("h5_log", h5_log)
        }
        output += component("trace_id", trace_id)
        if !install_id.isEmpty {
            output += component("install_id", install_id)
        }
        return output
    }
}

class UploadLogRequestBody {
    /**
     * header : {"device_id":"43891908782","device_model":"Android_Xiaomi","display_name":"Lark","os_version":"3.1.0","aid":"1161","os":"macos","sdk_version":"2.9.4","seq_id":"1558","tenant_id":"1","version":"2.9.5"}
     * data : [{"data":"{\"message\":\"fetch: channel= CronetQuic domain= \\\"internal-api-lark-api-hl.feishu.cn\\\" ip= Some(\\\"119.249.48.237\\\") cmd= 0 code= 200 cost= 44 protocol= Some(\\\"quic\\\")  c_point=\\\"0de343248e1f48aa3e430bf3b6b28e34fe79e254\\\"  req_id= \\\"ABCDEFD-ABGESET\\\"\",\"target\":\"lib_net::client::fetch::helpers\",\"time\":\"2019-06-20T21:42:28.732151+08:00\",\"module_path\":\"lib_net::client::fetch::helpers\",\"pid\":20857,\"thread\":\"t:worker-12\",\"file\":\"lib-net/src/client/fetch/helpers.rs\",\"level\":\"INFO\",\"line\":355}","log_type":"rust_sdk_log"}]
     */

    var header: HeaderModel
    var data: [DataModel]

    init(header: HeaderModel, data: [DataModel]) {
        self.header = header
        self.data = data
    }

    func dict() -> [String: Any] {
        let dataArray = data.map { (data) -> [String: Any] in return data.dict() }
        return [
            "header": header.dict(),
            "data": dataArray
        ]
    }
}

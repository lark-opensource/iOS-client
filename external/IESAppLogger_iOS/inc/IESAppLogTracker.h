#pragma once

#include <string>
namespace IESAppLogger {

class AppLogTracker {
public:
    /**
     * 全局开启上报
     */
    static void enableAllReports();
    /**
     * 全局关闭上报
     */
    static void disableAllReports();
    /**
     * 是否另上传至业务仓
     */
    void setReportToBusiness(bool);
public:
    /**
     * 构造AppLogTracker。数据在AppLogTracker析构时进行发送。
     * @param chEventName 事件名称
     * @param chEventType 事件类型
     */
    AppLogTracker(const char *chEventName, const char *chEventType);
    AppLogTracker(std::string eventName, std::string eventType);
    ~AppLogTracker();

    /**
     * 添加日志数据
     * @param key 数据Key
     * @param val 数据Value
     * @return *this
     *
     * 数据将转换成字符串后进行上报。
     */
    AppLogTracker& putVal(const std::string& key, int val);
    AppLogTracker& putVal(const std::string& key, int64_t val);
    AppLogTracker& putVal(const std::string& key, uint64_t val);
    AppLogTracker& putVal(const std::string& key, float val);
    AppLogTracker& putVal(const std::string& key, double val);
    AppLogTracker& putVal(const std::string& key, const std::string& val);
    AppLogTracker& putVal(const std::string& key, const char* val);

    /**
     * 添加日志数据（列表）
     * @param key 数据Key
     * @param count 数据数量
     * @param vals 数据列表
     * @return *this
     *
     * 多条数据将合并成用","隔开的字符串进行上报。
     */
    AppLogTracker& putVals(const std::string& key, int count, int* vals);
    AppLogTracker& putVals(const std::string& key, int count, int64_t* vals);
    AppLogTracker& putVals(const std::string& key, int count, uint64_t* vals);
    AppLogTracker& putVals(const std::string& key, int count, float* vals);
    AppLogTracker& putVals(const std::string& key, int count, double* vals);
    AppLogTracker& putVals(const std::string& key, const std::vector<std::string>& vals);
private:
    class Impl;
    std::unique_ptr<Impl> pimpl;
    AppLogTracker() = delete;
    AppLogTracker(const AppLogTracker &) = delete;
    AppLogTracker& operator=(const AppLogTracker&) = delete;
    AppLogTracker(const AppLogTracker &&) = delete;
};

} 

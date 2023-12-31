//
// Created by bytedance on 2021/3/22.
//

#ifndef NLECONSOLE_NLEFILEDESCRIPTOR_H
#define NLECONSOLE_NLEFILEDESCRIPTOR_H

#if defined(__ANDROID__)

#include <string>

const  std::string COMMON_PREFIX = "content";//uri字符串的前缀，documentUI和contentresolver均以这种方式获取
const  int URI_MAX_LEN = 1024;
const  int ANDROID_Q_ERROR = -29;

#include <jni.h>
static jobject obj_file_descriptor = nullptr;
static void android_jni_thread_destroy(void *value); //线程退出时，detachthreadenv，用于对象跨进程时能够在attach的thread上正常detach

class NLEFileDescriptor {

public:
    NLEFileDescriptor();
    ~NLEFileDescriptor();
    void closeFd();
    int getFd(const std::string &strFilePath);


protected:

private:
    int fd = -1;
#if defined(__ANDROID__)
    jobject obj_file_descriptor = nullptr;
#endif
};
#endif

#endif //NLECONSOLE_NLEFILEDESCRIPTOR_H

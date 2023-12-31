//
// Created by wangchengyi.1 on 2021/4/13.
//

#ifndef DAVINCIRESOURCEDEMO_DAVPUBDEFINE_H
#define DAVINCIRESOURCEDEMO_DAVPUBDEFINE_H

#ifdef _MSC_VER
#define DAV_EXPORT __declspec(dllexport)
#else
#define DAV_EXPORT __attribute__((visibility("default")))
#endif

#define RESOURCE_PROPERTY_DEC(__TYPE, __NAME)                                               \
public:                                                                                     \
    virtual __TYPE get##__NAME() const;                                                     \
    virtual void set##__NAME(const __TYPE& value);                                          \
private:                                                                                    \
    __TYPE __NAME;                                                                          \


#define RESOURCE_PROPERTY_IMP_SET(__CLASS, __TYPE, __NAME)                                  \
void __CLASS::set##__NAME(const __TYPE &value) {                                            \
    this->__NAME = value;                                                                   \
}

#define RESOURCE_PROPERTY_IMP_GET(__CLASS, __TYPE, __NAME)                                  \
__TYPE __CLASS::get##__NAME() const {                                                       \
        return this->__NAME;                                                                \
}                                                                                           \

#define RESOURCE_PROPERTY_IMP(__CLASS, __TYPE, __NAME)                                      \
RESOURCE_PROPERTY_IMP_SET(__CLASS, __TYPE, __NAME)                                          \
RESOURCE_PROPERTY_IMP_GET(__CLASS, __TYPE, __NAME)                                          \

/// 为了解决iOS lint问题
#define ENUM_INTERFACE(type, x) static const type & x(void);
#define ENUM_IMPLEMENT(type, x, value) \
const type & x(){ \
    static std::string ls = value; \
    return ls; \
}

#define ENUM_STR_INTERFACE(x) ENUM_INTERFACE(std::string, x)
#define ENUM_STR_IMPLEMENT(x, value) ENUM_IMPLEMENT(std::string, x, value)


#include <string>

namespace davinci {
    namespace resource {
        typedef std::string DavinciResourceId;
        typedef std::string DavinciResourceFile;
        typedef int64_t DAVResourceTaskHandle;
        typedef int32_t DRResult;
    }
}
#endif //DAVINCIRESOURCEDEMO_DAVPUBDEFINE_H

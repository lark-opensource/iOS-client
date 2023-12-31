//
// Created by bytedance on 2020/8/6.
//

#ifndef HERMAS_RECORDS_H
#define HERMAS_RECORDS_H

#include <map>

#include "file_record.h"
#include "env.h"
#include "file_service.h"
#include "protocol_service.h"

namespace hermas {

class Records final {

public:
    explicit Records(const std::shared_ptr<Env>& env);
    ~Records();

    void RecordFile(int type, const std::string& content);
    void SetFileService(const std::shared_ptr<FileService>& file_service);
    void SaveFile(int type, bool need_drop = false);

private:
    std::shared_ptr<Env> m_env;
    std::shared_ptr<FileService> m_file_service;
    std::map<int, std::unique_ptr<IFileRecord>> m_record_struct_map;
};

} //namespace hermas

#endif //HERMAS_RECORDS_H

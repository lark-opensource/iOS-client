//
//  cache_service.h
//  Hermas
//
//  Created by 崔晓兵 on 28/1/2022.
//

#ifndef cache_service_hpp
#define cache_service_hpp

#include <string>
#include <functional>
#include <thread>
#include <deque>

#include "env.h"
#include "log.h"


namespace hermas {

class MmapReadFile;
class MmapWriteFile;
class FilesCollect;

using FSQueue = std::deque<std::unique_ptr<FilesCollect>>;

class CacheService: public std::enable_shared_from_this<CacheService> {
 
public:
    explicit CacheService(const std::shared_ptr<Env>& env) : m_env(env){}
    
    virtual ~CacheService(){}
    
    void WriteBack();
    
private:
    FSQueue CollectFileDirs();
    
    bool NeedUpload(const std::string& content, std::string& after_content);
    
    std::unique_ptr<MmapReadFile> GenerateFileReader(FilePath& file_path);
    
    std::unique_ptr<MmapWriteFile> GenerateFileWriter(const FilePath& file_path);
    
    bool Record(std::unique_ptr<MmapWriteFile>& file_writer, const std::string& content);
    
    void RenameRetryFiles(std::vector<FilePath>& rename_file_list);
    
    FilePath GenCache2ReadyFile(const FilePath& file_path);
    
    FilePath GenCache2LocalFile(const FilePath& file_path);
    
    void MoveCache2ReadyFile(const FilePath& file_path);
    
    void MoveCache2LocalFile(const FilePath& file_path);
    
private:
    std::shared_ptr<Env> m_env;
    std::vector<FilePath> m_rename_file_list;
};

}  //namespace hermas

#endif /* cache_service_h */

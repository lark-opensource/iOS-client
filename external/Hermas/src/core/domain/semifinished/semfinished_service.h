//
//  semifinished_service.hpp
//  Hermas
//
//  Created by liuhan on 2022/3/31.
//

#ifndef semifinished_service_h
#define semifinished_service_h

#include "env.h"
#include "semi_mmap_file.h"
#include "semifinished_helper.h"


namespace hermas {

class MmapWriteFile;

class SemifinishedService {
    
public:
    explicit SemifinishedService(const std::shared_ptr<Env>& env, bool should_new = true);
    
    ~SemifinishedService() = default;

public:
    
    void StartTraceRecord(const std::string& data, const std::string& traceID);
    
    void StartSpanRecord(const std::string& data, const std::string& traceID, const std::string& spanID);
    
    void FinishTraceRecord(const std::string& data, const std::string& traceID, const std::string& spanIDList);
    
    void FinishSpanRecord(const std::string& data, const std::string& traceID, const std::string& spanID);
    
    void DeleteRecords(const std::string& traceID, const std::string& spanIDList);
    
    void LaunchReportForSemi();
    
    void RemoveSemiFiles();
    
private:
    void NewSemiFile(int file_size);
    const FilePath GenSemiDirPath();
    FilePath GenSemi2ReadyFile(const FilePath& file_path);
    void MoveSemi2ReadyFile(const FilePath& file_path);
    std::unique_ptr<MmapWriteFile> GenerateNormalMmapFileWriter(const FilePath& file_path);
    std::unique_ptr<SemiMmapFile> GenerateSemiMmapFileReader(const FilePath& file_path);
    
    bool isValidTrace(const std::string& traceID);
    bool isValidSpan(const std::string& traceID, const std::string& spanID);
    
    
private:
    std::shared_ptr<Env> m_env;
    int m_id = 0;
    std::unique_ptr<SemiMmapFile> m_semi_file_id;
};
    


} //namespace hermas

#endif /* semifinished_service_hpp */

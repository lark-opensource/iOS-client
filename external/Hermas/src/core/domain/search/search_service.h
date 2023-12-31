//
//  search_service.h
//  Hermas
//
//  Created by 崔晓兵 on 28/1/2022.
//

#ifndef search_service_h
#define search_service_h

#include <string>
#include <vector>
#include "env.h"

namespace hermas {

class ConditionNode;
class FileService;
class MmapReadFile;

struct SearchData {
    std::string filename;
    std::vector<std::string> records;
};

class SearchService {
 
public:
    explicit SearchService(const std::shared_ptr<Env>&env) : m_env(env) {}
    
    virtual ~SearchService() {}
    
    std::vector<std::unique_ptr<SearchData>> Search(const std::shared_ptr<hermas::ConditionNode>& condition);
    
private:
    std::unique_ptr<MmapReadFile> GenerateFileReader(FilePath& file_path);
    
private:
    std::shared_ptr<Env> m_env;
};

}  //namespace hermas

#endif /* search_service_h */

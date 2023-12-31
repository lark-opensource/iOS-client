//
//  session_service.h
//  Hermas
//
//  Created by liuhan on 2022/2/24.
//

#ifndef session_service_h
#define session_service_h

#include "aggre_mmap_file.h"
#include "singleton.hpp"

namespace hermas {

class SessionService : public Singleton<SessionService> {
public:
    void UpdateSessionRecord(const std::string& sessionRecord);
    std::string GetLatestSession();
    
    virtual ~SessionService(){};
    
private:
    void NewSessionFile();
    
private:
    explicit SessionService(const std::string& session_dir_path);
   
    
private:
    const FilePath session_dir_path;
    std::unique_ptr<AggreMmapFile> session_file_id;
    
    friend class Singleton<SessionService>;
};

} // namespace hermas

#endif /* session_service_h */

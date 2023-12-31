//
//  FileSystem.hpp
//  VideoTemplate
//
//  Created by lxp on 2020/2/9.
//

#ifndef FileSystem_hpp
#define FileSystem_hpp
#include <string>
namespace asve {
namespace filesystem {
bool DirectoryExist(const std::string& path);
bool FileExist(const std::string& path);
bool CreateDirectory(const std::string& path);
bool CopyDirectory(const std::string& src, const std::string& dst, bool recursive);
bool CopyFile(const std::string& src, const std::string& dst);
}
}

#endif /* FileSystem_hpp */

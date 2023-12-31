//
// Created by 天 on 2019-12-09.
//

#ifndef CUTSAMEAPP_FILEUTILS_H
#define CUTSAMEAPP_FILEUTILS_H

#include <string>


namespace asve {
    class FileUtils {
    public:
        static std::string getFontPath(const std::string& fontDir);
    };

//{
//  if (bfs::exists(dst)){
//    throw std::runtime_error(dst.generic_string() + " exists");
//  }
//
//  if (bfs::is_directory(src)) {
//    bfs::create_directories(dst);
//    for (bfs::directory_entry& item : bfs::directory_iterator(src)) {
//      recursive_copy(item.path(), dst/item.path().filename());
//    }
//  }
//  else if (bfs::is_regular_file(src)) {
//    bfs::copy(src, dst);
//  }
//  else {
//    throw std::runtime_error(dst.generic_string() + " not dir or file");
//  }
//}
}


#endif //CUTSAMEAPP_FILEUTILS_H

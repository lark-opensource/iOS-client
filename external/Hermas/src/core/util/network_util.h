//
//  network_util.hpp
//  Hermas
//
//  Created by liuhan.6985.lh on 2023/9/5.
//

#ifndef network_util_hpp
#define network_util_hpp

#include <stdio.h>
#include <string>

namespace hermas {
std::string urlWithHostAndPath(const std::string& host, const std::string& path = "");
}


#endif /* network_util_hpp */

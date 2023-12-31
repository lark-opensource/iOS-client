//
//  HMDGetImages.hpp
//  Heimdallr
//
//  Created by APM on 2022/9/1.
//

#ifndef HMDGetImages_hpp
#define HMDGetImages_hpp

#include <stdio.h>
#include <mach-o/loader.h>
#include <vector>
#include <unordered_map>
#include <string>
#include <set>

std::vector<std::string> getPreloadDylibPath();

#endif /* HMDGetImages_hpp */

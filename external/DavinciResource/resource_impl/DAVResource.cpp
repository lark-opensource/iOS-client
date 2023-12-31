//
// Created by wangchengyi.1 on 2021/4/7.
//

#include "DAVResource.h"
#include <iostream>
#include <string>
#include <sstream>

using namespace davinci::resource;

DAVResource::DAVResource(DavinciResourceId davinciResourceId) : ResourceId(std::move(davinciResourceId)){

}

RESOURCE_PROPERTY_IMP(DAVResource, DavinciResourceId, ResourceId)
RESOURCE_PROPERTY_IMP(DAVResource, std::string, ResourceFile)

std::string DAVResource::toString() {
    std::stringstream result;
    result << "resourceId: " << ResourceId << "  resourceFile: " << ResourceFile;
    return result.str();
}
//
// Created by wangchengyi.1 on 2021/4/29.
//

#include "DAVResourceProtocol.h"
#include "DAVPublicUtil.h"

using davinci::resource::DAVResourceProtocol;

davinci::resource::DavinciResourceId DAVResourceProtocol::toResourceId() {
    return DAVINCI_RESOURCE_SCHEMA + getSourceFrom() + DAVPublicUtil::map_to_query_params(getParameters(),
                                                                                          false);
}
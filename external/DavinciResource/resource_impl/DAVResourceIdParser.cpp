//
// Created by wangchengyi.1 on 2021/4/13.
//

#include "DAVResourceIdParser.h"
#include <algorithm>
#include <cctype>
#include <functional>
#include "DAVPublicUtil.h"

using std::string;
using namespace std;

davinci::resource::DAVResourceIdParser::DAVResourceIdParser(const davinci::resource::DavinciResourceId &resourceId) {
    const string prot_end("://");
    auto prot_i = search(resourceId.begin(), resourceId.end(),
                         prot_end.begin(), prot_end.end());
    protocol.reserve(std::distance(resourceId.begin(), prot_i));
    transform(resourceId.begin(), prot_i,
              back_inserter(protocol),
              std::ptr_fun<int, int>(tolower));
    if (prot_i == resourceId.end())
        return;
    advance(prot_i, prot_end.length());
    auto query_i = find(prot_i, resourceId.end(), '?');
    host.reserve(distance(prot_i, query_i));
    transform(prot_i, query_i,
              back_inserter(host),
              ptr_fun<int, int>(tolower));
    if (query_i != resourceId.end())
        ++query_i;
    query.assign(query_i, resourceId.end());

    queryParams = DAVPublicUtil::query_params_to_map(query);
}

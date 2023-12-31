//
// Created by wangchengyi.1 on 2021/4/29.
//

#include "DAVPublicUtil.h"
#include <sstream>
#include <algorithm>
#include <iterator>

using davinci::resource::DAVPublicUtil;

void davinci::resource::DAVPublicUtil::hexChar(unsigned char c, unsigned char &hex1, unsigned char &hex2) {
    hex1 = c / 16;
    hex2 = c % 16;
    hex1 += hex1 <= 9 ? '0' : 'a' - 10;
    hex2 += hex2 <= 9 ? '0' : 'a' - 10;
}

char davinci::resource::DAVPublicUtil::fromHex(char ch) {
    return isdigit(ch) ? ch - '0' : tolower(ch) - 'a' + 10;
}

std::string DAVPublicUtil::urlEncode(const std::string &s) {
    const char *str = s.c_str();
    std::vector<char> v(s.size());
    v.clear();
    for (size_t i = 0, l = s.size(); i < l; i++) {
        char c = str[i];
        if ((c >= '0' && c <= '9') ||
            (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            c == '-' || c == '_' || c == '.' || c == '!' || c == '~' ||
            c == '*' || c == '\'' || c == '(' || c == ')') {
            v.push_back(c);
        } else if (c == ' ') {
            v.push_back('+');
        } else {
            v.push_back('%');
            unsigned char d1, d2;
            hexChar(c, d1, d2);
            v.push_back(d1);
            v.push_back(d2);
        }
    }
    return std::string(v.cbegin(), v.cend());
}

std::string DAVPublicUtil::urlDecode(const std::string &s) {
    const char *pstr = s.c_str();
    char *buf = (char *) malloc(s.length() + 1), *pbuf = buf;
    while (*pstr) {
        if (*pstr == '%') {
            if (pstr[1] && pstr[2]) {
                *pbuf++ = fromHex(pstr[1]) << 4 | fromHex(pstr[2]);
                pstr += 2;
            }
        } else if (*pstr == '+') {
            *pbuf++ = ' ';
        } else {
            *pbuf++ = *pstr;
        }
        pstr++;
    }
    *pbuf = '\0';
    auto result = std::string(buf);
    free(buf);
    return result;
}

std::string
DAVPublicUtil::map_to_query_params(const std::unordered_map<std::string, std::string> &map, bool withEncode) {
    if (map.empty()) {
        return "";
    }
    std::string result;
    std::for_each(std::begin(map),
                  std::end(map),
                  [&](auto const &param) {
                      result += ("&" + param.first + "=" +
                                 (withEncode ? urlEncode(param.second) : param.second));
                  });
    // Just convert the first '&' into '?'
    result[0] = '?';
    return result;
}

std::vector<std::string> DAVPublicUtil::split(const std::string &str, const std::string &delim) {
    std::vector<std::string> tokens;
    size_t prev = 0, pos = 0;
    do {
        pos = str.find(delim, prev);
        if (pos == std::string::npos) pos = str.length();
        std::string token = str.substr(prev, pos - prev);
        if (!token.empty()) tokens.push_back(token);
        prev = pos + delim.length();
    } while (pos < str.length() && prev < str.length());
    return tokens;
}

std::unordered_map<std::string, std::string> DAVPublicUtil::query_params_to_map(const std::string &queryString) {
    std::unordered_map<std::string, std::string> map;
    if (queryString.empty()) {
        return map;
    }
    auto params = split(queryString, "&");
    for (const auto &param: params) {
        auto valueIndex = find(param.begin(), param.end(), '=');
        std::string key, value;
        key.assign(param.begin(), valueIndex);
        value.assign(valueIndex + 1, param.end());
        map.emplace(std::make_pair(key, value));
    }
    return map;
}

std::string
DAVPublicUtil::vector_join_to_string(const std::vector<std::string> &vecString, const std::string &delim,
                                     const std::string &start, const std::string &end) {
    std::ostringstream os;
    if (!vecString.empty()) {
        std::copy(vecString.begin(), vecString.end() - 1,
                  std::ostream_iterator<std::string>(os, delim.c_str()));
        os << *vecString.rbegin();
    }
    return start + os.str() + end;
}
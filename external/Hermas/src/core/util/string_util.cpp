#include "string_util.h"
#include <string>
#include <vector>


namespace hermas {

#if defined(HERMAS_WIN)
#include <Windows.h>
std::wstring StringToWString(const std::string&str) {
    int len = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, NULL, 0);
    wchar_t *wide = new wchar_t[len + 1];
    memset(wide, '\0', sizeof(wchar_t) * (len + 1));
    MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, wide, len);
    std::wstring w_str(wide);
    delete[] wide;
    return w_str;
}

std::string WStringToString(const std::wstring &wstr) {
    int len = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), wstr.size(), NULL, 0, NULL, NULL);
    char *buffer = new char[len + 1];
    memset(buffer, '\0', sizeof(char) * (len + 1));
    WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), wstr.size(), buffer, len, NULL, NULL);
    std::string result(buffer);
    delete[] buffer;
    return result;
}

std::string SString(const std::wstring& wstr) {
    return WStringToString(wstr); 
}

#endif

std::string SString(const std::string& str) {
    return str; 
}

std::string StrToLower(const std::string& str) {
    std::string res = str;
    std::transform(res.begin(), res.end(), res.begin(), tolower);
    return res;
}

std::string SpaceString(int length) {
    std::string spaceStr;
    spaceStr.resize(length, ' ');
    return spaceStr;
}

std::string& ltrim(std::string& s) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](int c) {return !std::isspace(c);}));

    return s;
}

std::string& rtrim(std::string& s) {
    s.erase(std::find_if(s.rbegin(), s.rend(),
                         [](int c) {return !std::isspace(c);})
                .base(),
            s.end());
    return s;
}

std::string& trim(std::string& s) {
    return ltrim(rtrim(s));
}

std::vector<std::string> SplitStringPiece(std::string str,
                                                 std::string delimiter,
                                                 WhitespaceHandling whitespace,
                                                 SplitResult result_type) {
    std::vector<std::string> result;
    if (str.empty())
        return result;

    size_t start = 0;
    while (start != std::string::npos) {
        size_t end = str.find_first_of(delimiter, start);

        std::string piece;
        if (end == std::string::npos) {
            piece = str.substr(start);
            start = std::string::npos;
        }
        else {
            piece = str.substr(start, end - start);
            start = end + 1;
        }

        if (whitespace == WhitespaceHandling::TRIM_WHITESPACE)
            piece = trim(piece);

        if (result_type == SplitResult::SPLIT_WANT_ALL || !piece.empty())
            result.emplace_back(piece);
    }
    return result;
}

bool isPrefix(const std::string& originStr, const std::string& prefix) {
    bool isPrefix = originStr.rfind(prefix, 0) == 0;
    return isPrefix;
}

bool isSuffix(const std::string& originStr, const std::string& suffix) {
    if (suffix.length() > originStr.length()) {
        return false;
    }
    bool isSuffix = originStr.rfind(suffix) == (originStr.length() - suffix.length());
    return isSuffix;
}

}

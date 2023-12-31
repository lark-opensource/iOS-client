//
// Created by kilroy on 2021/6/9.
//

#ifndef HERMAS_STRING_UTIL_H
#define HERMAS_STRING_UTIL_H

#include <string>

#if defined(HERMAS_WIN)
#include <wchar.h>
// Windows上 Unicode敏感应用的原生路径是wchar_t数组，编码方式为UTF-16.
#define CharType wchar_t
#define CHAR_LITERAL(x) L ## x
#define CHARTYPE_LEN(x) wcslen(x)
#define CHARTYPE_CPY(x, y) wcscpy(x, y)
#define CHARTYPE_DUP(x) _wcsdup(x)
#define CHARTYPE_NCPY(x, y, z) wcsncpy(x,y,z)
#define CHARTYPE_CHR(x, y) wcschr(x,y)
#define CHARTYPE_NCMP(x, y, z) wcsncmp(x, y, z)
#else
// 绝大部分平台原生路径是char数组类型，编码是不确定的
// macOS上为UTF8
#define CharType char
#define CHAR_LITERAL(x) x
#define CHARTYPE_LEN(x) strlen(x)
#define CHARTYPE_CPY(x, y) strcpy(x, y)
#define CHARTYPE_DUP(x) _strdup(x)
#define CHARTYPE_NCPY(x, y, z) strncpy(x, y, z)
#define CHARTYPE_CHR(x, y) strchr(x, y)
#define CHARTYPE_NCMP(x, y, z) strncmp(x, y, z)
#endif

#if defined(HERMAS_WIN)
    // Windows上 Unicode敏感应用的原生路径是wchar_t数组，编码方式为UTF-16.
#define TO_STRING(x) std::to_wstring(x)
#define RENAME_FILE(x,y) _wrename(x,y)
#define STR_TO_INT(x) _wtoi(x)
    using StringType = std::wstring;
#else
    // 绝大部分平台原生路径是char数组类型，编码是不确定的
    // macOS上为UTF8
#define TO_STRING(x) std::to_string(x)
#define RENAME_FILE(x,y) std::rename(x,y)
#define STR_TO_INT(x) std::atoi(x)
    using StringType = std::string;
#endif

namespace hermas {

enum class WhitespaceHandling
{
  KEEP_WHITESPACE,
  TRIM_WHITESPACE,
};

enum class SplitResult
{
  // Strictly return all results.
  //
  // If the input is ",," and the separator is ',' this will return a
  // vector of three empty strings.
  SPLIT_WANT_ALL,

  // Only nonempty results will be added to the results. Multiple separators
  // will be coalesced. Separators at the beginning and end of the input will
  // be ignored. With TRIM_WHITESPACE, whitespace-only results will be dropped.
  //
  // If the input is ",," and the separator is ',', this will return an empty
  // vector.
  SPLIT_WANT_NONEMPTY,
};

const char kWhitespaceASCII[] = " \f\n\r\t\v";


#if defined(HERMAS_WIN)
    std::wstring StringToWString(const std::string&str);
    std::string WStringToString(const std::wstring &wstr);
	std::string SString(const std::wstring& wstr);
#endif
	std::string SString(const std::string& str);

std::string StrToLower(const std::string& str);

std::string SpaceString(int length);

// trim from start
std::string& ltrim(std::string& s);

// trim from end
std::string& rtrim(std::string& s);

// trim from both ends
std::string& trim(std::string& s);

// split string into pieces
std::vector<std::string> SplitStringPiece(std::string str, std::string delimiter, WhitespaceHandling whitespace, SplitResult result_type);

bool isPrefix(const std::string& originStr, const std::string& prefix);

bool isSuffix(const std::string& originStr, const std::string& suffix);
}
#endif // HERMAS_STRING_UTIL_H

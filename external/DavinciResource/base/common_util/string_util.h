/*
 * string_util.h
 */

#ifndef _UTIL_STRING_UTIL_H_
#define _UTIL_STRING_UTIL_H_

#include <cstddef>
#include <cctype>

#include <string>
#include <vector>
#include <deque>
#include <list>
#include <set>
#include <functional>
#include <algorithm>
#include "lexical_cast.h"

namespace cbox {

using namespace std::placeholders;

template <typename T>
inline void insert(std::vector<T>& v, const T& value) {
	v.push_back(value);
}

template <typename T, typename U>
inline void insert(std::vector<T>& v, const U& value) {
	v.push_back(lexical_cast<T>(value));
}

template <typename T>
inline void insert(std::deque<T>& d, const T& value) {
	d.push_back(value);
}

template <typename T, typename U>
inline void insert(std::deque<T>& v, const U& value) {
	v.push_back(lexical_cast<T>(value));
}

template <typename T>
inline void insert(std::list<T>& l, const T& value) {
	l.push_back(value);
}

template <typename T, typename U>
inline void insert(std::list<T>& v, const U& value) {
	v.push_back(lexical_cast<T>(value));
}

template <typename T>
inline void insert(std::set<T>& s, const T& value) {
	s.insert(value);
}

template <typename T, typename U>
inline void insert(std::set<T>& v, const U& value) {
	v.insert(lexical_cast<T>(value));
}

template <typename T>
inline void insert(std::multiset<T>& s, const T& value) {
	s.insert(value);
}

template <typename T, typename U>
inline void insert(std::multiset<T>& v, const U& value) {
	v.insert(lexical_cast<T>(value));
}


template <typename Container>
size_t split(Container& tokens, const std::string& s,
		const std::string& delims = " ", int limit = 0) {

    std::string::size_type curr_pos = 0, prev_pos = 0, count = 0;
    while (--limit != 0 && (curr_pos = s.find_first_of(delims, prev_pos)) != std::string::npos) {
        count = curr_pos - prev_pos;
        if (count != 0) {
            insert(tokens, s.substr(prev_pos, count));
        }
        prev_pos = curr_pos + 1;
    }

    count = s.size() - prev_pos;
    if (count != 0) {
    	 insert(tokens, s.substr(prev_pos, count));
    }

    return tokens.size();
}

template <typename Container>
size_t split_ex(Container& tokens, const std::string& s,
		const std::string& delims = " ", int limit = 0) {

    std::string::size_type curr_pos = 0, prev_pos = 0, count = 0;
    while (--limit != 0 && (curr_pos = s.find_first_of(delims, prev_pos)) != std::string::npos) {
        count = curr_pos - prev_pos;
        insert(tokens, s.substr(prev_pos, count));
        prev_pos = curr_pos + 1;
    }

    count = s.size() - prev_pos;
    insert(tokens, s.substr(prev_pos, count));

    return tokens.size();
}

std::string& trim(std::string& s, const std::string& delims = " ");
std::string& ltrim(std::string& s, const std::string& delims = " ");
std::string& rtrim(std::string& s, const std::string& delims = " ");

std::string trim(const std::string& s, const std::string& delims = " ");
std::string ltrim(const std::string& s, const std::string& delims = " ");
std::string rtrim(const std::string& s, const std::string& delims = " ");

std::string& replace(std::string& s, const std::string& old_value, const std::string& new_value);
std::string& replace(std::string& s, const std::string& old_value, size_t num, char c);

inline std::string& replace(std::string& s, char old_value, char new_value) {
	std::replace_if(s.begin(), s.end(), std::bind(std::equal_to<char>(), _1, old_value), new_value);
	return s;
}

inline std::string& lower_case(std::string& s) {
	std::transform(s.begin(), s.end(), s.begin(), ::tolower);
	return s;
}

inline std::string lower_case(const std::string& s) {
	std::string result(s);
	return lower_case(result);
}

inline std::string& upper_case(std::string& s) {
	std::transform(s.begin(), s.end(), s.begin(), ::toupper);
	return s;
}

inline std::string upper_case(const std::string& s) {
	std::string result(s);
	return upper_case(result);
}

// tests if string 's' starts with the specified 'prefix' beginning a specified index 'pos'
bool starts_with(const std::string& s, const std::string& prefix, size_t pos = 0);

// tests if string 's' ends with the specified 'suffix'
bool ends_with(const std::string& s, const std::string& suffix);

// convert byte array to hex string
std::string to_hex_string(const void* buffer, size_t length);
std::string to_hex_string(const std::string& buffer);
std::string from_hex_string(const std::string& hex);
bool from_hex_string(const char* hex, size_t hex_size, unsigned char* buffer, size_t buffer_size);

} //namespace cbox

#endif /* _UTIL_STRING_UTIL_H_ */

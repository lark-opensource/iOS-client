/*
 * string_util.cpp
 */

#include "string_util.h"

#include <cstdint>

namespace cbox {

std::string& trim(std::string& s, const std::string& delims /*= " "*/) {
	// trim right
	std::string::size_type pos = s.find_last_not_of(delims);
	if (pos == std::string::npos) {
		s.clear();
		return s;
	} else if (pos + 1 != s.size()) {
		s.erase(pos + 1);
	}

	// trim left
	pos = s.find_first_not_of(delims);
	if (pos == std::string::npos) {
		s.clear();
	} else {
		s.erase(0, pos);
	}

	return s;
}

std::string& ltrim(std::string& s, const std::string& delims /*= " "*/) {
	std::string::size_type pos = s.find_first_not_of(delims);
	if (pos == std::string::npos) {
		s.clear();
	} else {
		s.erase(0, pos);
	}

	return s;
}

std::string& rtrim(std::string& s, const std::string& delims /*= " "*/) {
	std::string::size_type pos = s.find_last_not_of(delims);
	if (pos == std::string::npos) {
		s.clear();
	} else if (pos + 1 != s.size()) {
		s.erase(pos + 1);
	}

	return s;
}

std::string trim(const std::string& s, const std::string& delims /*= " "*/) {
	std::string::size_type begin = s.find_first_not_of(delims);
	if (begin == std::string::npos) {
		return "";
	}

	std::string::size_type end = s.find_last_not_of(delims);
	return s.substr(begin, end - begin + 1);
}

std::string ltrim(const std::string& s, const std::string& delims /*= " "*/) {
	std::string::size_type pos = s.find_first_not_of(delims);
	if (pos == std::string::npos) {
		return "";
	} else {
		return s.substr(pos);
	}
}

std::string rtrim(const std::string& s, const std::string& delims /*= " "*/) {
	std::string::size_type pos = s.find_last_not_of(delims);
	if (pos == std::string::npos) {
		return "";
	} else {
		return s.substr(0, pos + 1);
	}
}

std::string& replace(std::string& s, const std::string& old_value, const std::string& new_value) {
    size_t len_old = old_value.size(), len_new = new_value.size();
    std::string::size_type curr_pos = 0, prev_pos = 0;
    while ((curr_pos = s.find(old_value, prev_pos)) != std::string::npos) {
        s.replace(curr_pos, len_old, new_value);
        prev_pos = curr_pos + len_new;
    }
    return s;
}

std::string& replace(std::string& s, const std::string& old_value, size_t num, char c) {
    size_t len_old = old_value.size();
    std::string::size_type curr_pos = 0, prev_pos = 0;
    while ((curr_pos = s.find(old_value, prev_pos)) != std::string::npos) {
        s.replace(curr_pos, len_old, num, c);
        prev_pos = curr_pos + num;
    }
	return s;
}

bool starts_with(const std::string& s, const std::string& prefix, size_t pos /*= 0*/) {
	size_t size = s.size();
	size_t prefix_size = prefix.size();
	return (size >= prefix_size + pos) && (s.compare(pos, prefix_size, prefix) == 0);
}

bool ends_with(const std::string& s, const std::string& suffix) {
	size_t size = s.size();
	size_t suffix_size = suffix.size();
	return size >= suffix_size && (s.compare(size - suffix_size, suffix_size, suffix) == 0);
}

std::string to_hex_string(const void* buffer, size_t length) {
	static const char* HEX = "0123456789abcdef";

	const uint8_t* input = (const uint8_t*)buffer;

	std::string str;
	str.reserve(length << 1);
	for (size_t i = 0; i < length; ++i) {
		uint8_t t = input[i];
		// byte a = t / 16;
		uint8_t a = t >> 4;
		// byte b = t % 16;
		uint8_t b = t & 0x0f;
		str.append(1, HEX[a]);
		str.append(1, HEX[b]);
	}
	return str;
}

std::string to_hex_string(const std::string& buffer) {
    return to_hex_string(buffer.c_str(), buffer.size());
}

static int hexchar_to_int(char ch) {
    if ('0' <= ch && ch <= '9') {
        return ch - '0';
    }
    if ('a' <= ch && ch <= 'f') {
        return ch - 'a' + 10;
    }
    if ('A' <= ch && ch <= 'F') {
        return ch - 'A' + 10;
    }
    return -1;
}

std::string from_hex_string(const std::string& hex) {
    size_t hex_size = hex.size();
    if (hex_size == 0 || hex_size % 2 != 0) {
        return "";
    }
    
    std::string bytes;
    bytes.reserve(hex_size / 2);
    for (size_t i = 0; i < hex_size; i += 2) {
        int high = hexchar_to_int(hex[i]);
        int low = hexchar_to_int(hex[i + 1]);
        if (high == -1 || low == -1)
            return "";
        char ch = (high << 4) | low;
        bytes.append(1, ch);
    }
    return bytes;
}

bool from_hex_string(const char* hex, size_t hex_size, unsigned char* buffer, size_t buffer_size) {
    if (hex == nullptr || buffer == nullptr || hex_size == 0 || hex_size % 2 != 0) {
        return false;
    }
    
    size_t index = 0;
    for (size_t i = 0; i < hex_size && index < buffer_size; i += 2, ++index) {
        int high = hexchar_to_int(hex[i]);
        int low = hexchar_to_int(hex[i + 1]);
        if (high == -1 || low == -1)
            return false;
        unsigned char ch = (high << 4) | low;
        buffer[index] = ch;
    }
    return true;
}

} //namespace cbox

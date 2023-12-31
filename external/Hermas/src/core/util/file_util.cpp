//
// Created by bytedance on 2020/8/19.
//

#include <list>
#include <vector>
#include <sys/stat.h>
#include <iostream>
#include <fstream>
#include <algorithm>


#include "file_util.h"
#include "log.h"

#ifdef HERMAS_WIN
#include <windows.h>
#include <io.h>
#include "string_util.h"
#define STATSTRUCT _stat64i32
#define STAT(x, y) _wstat(x, y)
#pragma comment(lib, "User32.lib")
#else
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#define STATSTRUCT stat
#define STAT(x, y) stat(x, y)
#endif
namespace hermas {

std::vector<FilePath> GetFilesName(const FilePath& dir_path, FileSysType type) {

	std::vector<FilePath> files_name;
#ifdef HERMAS_WIN
	WIN32_FIND_DATAW ffd;
	HANDLE hFind = INVALID_HANDLE_VALUE;
	FilePath final_path = dir_path.Append("*");
	hFind = FindFirstFile(final_path.charValue(), &ffd);
	if (INVALID_HANDLE_VALUE != hFind) {
		do {
			if (ffd.cFileName[0] == L'.') continue;
			if (ffd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
				if (type == FileSysType::kOnlyFile) continue;
			}
			else {
				if (type == FileSysType::kOnlyFolder) continue;
			}
			//logi("hermas_util", "get file %s", SString(ffd.cFileName).c_str());
			files_name.push_back(FilePath(ffd.cFileName));
		} while (FindNextFileW(hFind, &ffd) != 0);
	}
	FindClose(hFind);
#else
	DIR *dir = opendir(dir_path.charValue());
	if (dir != NULL) {
		dirent *current_dir;
		while ((current_dir = readdir(dir)) != NULL) {
			// Default ignore hidden files
			if ( current_dir->d_name[0] == '.' ) continue;
			if ( current_dir->d_type == DT_DIR ) {
				if ( type == FileSysType::kOnlyFile ) continue;
			} else {
				if ( type == FileSysType::kOnlyFolder ) continue;
			}
			files_name.push_back(FilePath(current_dir->d_name));
		}
		closedir(dir);
	}
#endif
	std::sort(files_name.begin(), files_name.end());
	return files_name;
}

std::vector<FilePath> GetFilesNameRecursively(const FilePath& dir_path) {
    std::vector<FilePath> files_name;
    DIR *dir = opendir(dir_path.charValue());
    if (dir != NULL) {
        dirent *current_dir;
        while ((current_dir = readdir(dir)) != NULL) {
            // Default ignore hidden files
            if ( current_dir->d_name[0] == '.' ) continue;
            if ( current_dir->d_type == DT_DIR ) {
                auto ret = GetFilesNameRecursively(dir_path.Append(current_dir->d_name));
                files_name.insert(files_name.end(), ret.begin(), ret.end());
            } else {
                files_name.push_back(dir_path.Append(current_dir->d_name));
            }
        }
        closedir(dir);
    }
    return files_name;
}

long long GetFileSize(const FilePath& file_path) {
	struct STATSTRUCT info;
	if (STAT(file_path.charValue(), &info) != 0 ) return 0;
	return info.st_size;
}

void RenameFile(const FilePath& src_path, const FilePath& dst_path) {
    int result = std::rename(src_path.charValue(), dst_path.charValue());
    if (result != 0) {
        Mkdirs(dst_path.DirName());
        result = std::rename(src_path.charValue(), dst_path.charValue());
        if (result != 0) {
            // TODO monitor
            loge("hermas_file", "rename fail ! from %s to %s, result: %d, errorno = %d", src_path.sstrValue().c_str(), dst_path.sstrValue().c_str(), result, errno);
        }
    }
}

// Make dir at given path
bool Mkdir(const FilePath& path) {
#ifdef HERMAS_WIN
	if (CreateDirectory(path.charValue(), nullptr))
		return true;
	//logi("hermas_android", "mkdir error: %d", GetLastError());
	return GetLastError() == ERROR_ALREADY_EXISTS;
#else
	int result = mkdir(path.charValue(), ACCESSPERMS);
	if ( result == 0 ) {
		logi("hermas_file", "mkdir: %s success", path.charValue());
		return true;
	} else {
		//logi("hermas_android", "mkdir: %s failed, %d", path.c_str(), errno);
		//return true;
	}
   return errno == EEXIST;
#endif
}

bool Mkdirs(const FilePath& file_path) {
#ifdef HERMAS_WIN
	bool result = false;
	auto strDirPath = file_path.charValue();
	int ipathLength = CHARTYPE_LEN(file_path.charValue());
	int ileaveLength = 0;
	int iCreatedLength = 0;
	CharType szPathTemp[MAX_PATH] = { 0 };
	
	for (int i = 0; (NULL != CHARTYPE_CHR(strDirPath + iCreatedLength, CHAR_LITERAL('\\'))); i++)
	{
		ileaveLength = CHARTYPE_LEN(CHARTYPE_CHR(strDirPath + iCreatedLength, CHAR_LITERAL('\\'))) - 1;
		iCreatedLength = ipathLength - ileaveLength;
		CHARTYPE_NCPY(szPathTemp, strDirPath, iCreatedLength);
		result = Mkdir(FilePath(szPathTemp));
	}
	if (iCreatedLength < ipathLength)
	{
		result = Mkdir(file_path);
	}
	return result;
#else
	std::list< std::string > path_components;
	if (file_path.empty()) return true;
	std::string path = file_path.strValue();
	// Split the given path
	std::string::size_type processed_pos = 0;
	do {
		std::string::size_type last_pos = std::string::npos;
		std::string::size_type next_pos = path.find(SEPARATOR, processed_pos);
		if ( next_pos != std::string::npos ) {
			last_pos = next_pos;
		}
		if ( last_pos == std::string::npos ) last_pos = path.size();
		if ( last_pos > processed_pos ) {
			std::string com = path.substr( processed_pos, last_pos - processed_pos );
			path_components.emplace_back(com);
		}
		// Skip '/'
		processed_pos = last_pos + 1;
	} while( processed_pos < path.size() );

	std::string dir_path;
	// If is in linux or unix, add root path
	if ( path[0] == '/' ) dir_path = "/";

	while ( path_components.size() > 0 ) {
		dir_path += (*path_components.begin() + SEPARATOR);
		if ( !Mkdir(FilePath(dir_path)) ) {
			return false;
		}
		path_components.pop_front();
	}
	return true;
#endif
}

bool FillFileZero(int fd, size_t start_pos, size_t size) {
	if (fd < 0) {
		return false;
	}
    
#ifdef HERMAS_WIN
	if (_lseek(fd, start_pos, SEEK_SET) < 0) {
		return false;
	}
	static const char zeros[4096] = { 0 };
	while (size >= sizeof(zeros)) {
		if (_write(fd, zeros, sizeof(zeros)) < 0) {
			return false;
		}
		size -= sizeof(zeros);
	}
	if (size > 0) {
		if (_write(fd, zeros, size) < 0) {
			return false;
		}
	}

	return true;
#elif PLATFORM_ANDROID
	if (lseek(fd, start_pos, SEEK_SET) < 0) {
		return false;
	}
	static const char zeros[4096] = { 0 };
	while (size >= sizeof(zeros)) {
		if (write(fd, zeros, sizeof(zeros)) < 0) {
			return false;
		}
		size -= sizeof(zeros);
	}
	if (size > 0) {
		if (write(fd, zeros, size) < 0) {
			return false;
		}
	}

	return true;
#else
	return 0 == ftruncate(fd, size);
#endif
}

std::string GetFileData(const FilePath& file_path) {
	fstream file;
	file.open(file_path.charValue(), ios::in | ios::binary);
	if (!file) {
		loge("hermas_file", "open failed: %s", file_path.sstrValue().c_str());
		return "";
	}
	//这里buffer数值暂且为2048，估计不同的数值在不同的环境如果能够做更好的区分会有更好的效果。
	std::size_t read_size = 2048;
	file.exceptions(std::ios_base::badbit);
    std::string strdata;
    auto buf = std::string(read_size, '\0');
    while (file.read(& buf[0], read_size)) {
        strdata.append(buf, 0, file.gcount());
    }
    strdata.append(buf, 0, file.gcount());
	return strdata;
}

bool IsFileExits (FilePath& file_path) {
    struct STATSTRUCT info;
    return (STAT(file_path.charValue(), &info) == 0) ? true : false;
}

}


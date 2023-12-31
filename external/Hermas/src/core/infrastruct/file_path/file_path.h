//
//  file_path.h
//  hermas
//
//  Created by kilroy on 2021/7/12.
//
#pragma warning(2:4233)
#ifndef HERMAS_FILE_PATH_H_
#define HERMAS_FILE_PATH_H_

#include <stdio.h>
#include <string>
#include "string_util.h"

namespace hermas {
// 用于抽象路径在不同平台下的实现

#if defined(HERMAS_WIN)
#define FILE_PATH_USES_DRIVE_LETTERS
#define FILE_PATH_USES_WIN_SEPARATORS
#endif  // HERMAS_WIN

// 用于char类型的初始化
#if defined(HERMAS_WIN)
#define PRFilePath "ls"
#define PRFilePathLiteral L"%ls"
#elif defined(HERMAS_POSIX)
#define PRFilePath "s"
#define PRFilePathLiteral "%s"
#endif  // HERMAS_WIN

class FilePath {
 public:
	//有效分隔符的集合，kSeparators[0]是规范分隔符
	static const CharType kSeparators[];
	// 当前路径 './'
	static const CharType kCurrentDirectory[];
	// 父级目录 '../'
	static const CharType kParentDirectory[];
	// 文件拓展名
	static const CharType kExtensionSeparator;

	FilePath();
	explicit FilePath(const StringType& path);
	explicit FilePath(const CharType* path);
#if defined(HERMAS_WIN)
	explicit FilePath(const char* path);
#endif
	FilePath(const FilePath& that);
	FilePath& operator=(const FilePath& that);
	~FilePath();

	bool operator==(const FilePath& that) const;
	bool operator!=(const FilePath& that) const;
	// Required for some STL containers and operations
	bool operator<(const FilePath& that) const {
		return path_ < that.path_;
	}

	const StringType& strValue() const;
	const std::string sstrValue() const;
	const CharType* charValue() const;
	bool empty() const { return path_.empty(); }
	void clear() { path_.clear(); }

	// character是否为分隔符
	static bool IsSeparator(CharType character);
	// 返回当前路径的目录路径的FilePath对象
	FilePath DirName() const;
	// 返回当前路径的路径FilePath对象，可能是文件或者目录，包含拓展名
	FilePath FullBaseName() const;
	// 返回当前路径的路径FilePath对象，可能是文件或者目录，不包含拓展名
	FilePath BaseName() const;
	// 返回文件拓展名，如果没有的话返回“”
	// 如果拓展名为.tar.gz，只会返回.gz
	StringType FinalExtension() const;
	// 移除拓展名，返回FilePath对象
	FilePath RemoveFinalExtension() const;
	// 添加新的相对路径（组件名称），会自动在新组件名称前添加分隔符
	FilePath Append(const StringType& component) const;
	FilePath Append(const FilePath& component) const;
#if defined(HERMAS_WIN)
	FilePath Append(const char* component) const;
#endif

	/**
	 * 当前路径是否是绝对路径
	 * Win下绝对路径以两个分隔符或者以设备盘字符开头
	 * Posix平台以一个分隔符开头
	 */
	bool IsAbsolute() const;

 private:
	/** 移除尾随分隔符FilePath'\'
	 * 两种情况例外：
	 * 如果是绝对路径，尾随分隔符绝对不会被移除，所以"////"会变成"/"，而不是""
	 * C://的“//”也不会被移除，因为要支持Win的UNC路径
	 */
	void StripTrailingSeparatorsInternal();

	StringType path_;
};

}  // namespace hermas

#endif /* HERMAS_FILE_PATH_H_ */

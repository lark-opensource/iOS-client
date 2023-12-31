//
//  file_path.cpp
//  hermas
//
//  Created by kilroy on 2021/7/12.
//

#include "file_path.h"
#include "log.h"

namespace hermas {

#if defined(FILE_PATH_USES_WIN_SEPARATORS)
const CharType FilePath::kSeparators[] = CHAR_LITERAL("\\/");
#else  // FILE_PATH_USES_WIN_SEPARATORS
const CharType FilePath::kSeparators[] = CHAR_LITERAL("/");
#endif  // FILE_PATH_USES_WIN_SEPARATORS

const CharType FilePath::kCurrentDirectory[] = CHAR_LITERAL(".");
const CharType FilePath::kParentDirectory[] = CHAR_LITERAL("..");
const CharType FilePath::kExtensionSeparator = CHAR_LITERAL('.');

namespace {

const CharType kStringTerminator = CHAR_LITERAL('\0');

// 如果FilePath包含了盘符，返回盘符最后一个字符的位置，没有的话就返回npos
// 只在windows上生效(C://)，其他平台永远返回npos
StringType::size_type FindDriveLetter(const StringType& path) {
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
	// 依赖ASCII字符集
	if (path.length() >= 2 && path[1] == L':' &&
	((path[0] >= L'A' && path[0] <= L'Z') || (path[0] >= L'a' && path[0] <= L'z'))) {
		return 1;
	}
#endif
	return StringType::npos;
}

#if defined(FILE_PATH_USES_DRIVE_LETTERS)
bool EqualDriveLetterCaseInsensitive(const StringType& a, const StringType& b) {
  size_t a_letter_pos = FindDriveLetter(a);
  size_t b_letter_pos = FindDriveLetter(b);

  if (a_letter_pos == StringType::npos || b_letter_pos == StringType::npos)
	return a == b;

  if (::tolower(a[0]) != ::tolower(b[0]))
	return false;

  StringType a_rest(a.substr(a_letter_pos + 1));
  StringType b_rest(b.substr(b_letter_pos + 1));
  return a_rest == b_rest;
}
#endif

bool IsPathAbsolute(const StringType& path) {
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
	StringType::size_type letter = FindDriveLetter(path);
	if (letter != StringType::npos) {
		// 确认盘符后面一个字符是否为分隔符
		return path.length() > letter + 1 && FilePath::IsSeparator(path[letter + 1]);
	}
	// 确认最开始是否为“//”
	return path.length() > 1 && FilePath::IsSeparator(path[0]) && FilePath::IsSeparator(path[1]);
#else
  // 看第一个字符是否为分隔符
  return path.length() > 0 && FilePath::IsSeparator(path[0]);
#endif
}

}// namespace

FilePath::FilePath() {}

FilePath::FilePath(const FilePath& that) : path_(that.path_) {}

FilePath::FilePath(const StringType& path) : path_(path) {
	StringType::size_type nul_pos = path_.find(kStringTerminator);
	if (nul_pos != StringType::npos) {
		path_.erase(nul_pos, StringType::npos);
	}
}

FilePath::FilePath(const CharType* path) : path_(StringType(path)) {}

#if defined(HERMAS_WIN)
FilePath::FilePath(const char* path) {
	path_ = StringToWString(std::string(path));
}
#endif

FilePath::~FilePath() {}

FilePath& FilePath::operator=(const FilePath& that) {
	path_ = that.path_;
	return *this;
}

bool FilePath::operator==(const FilePath& that) const {
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
	return EqualDriveLetterCaseInsensitive(this->path_, that.path_);
#else
	return path_ == that.path_;
#endif
}

bool FilePath::operator!=(const FilePath& that) const {
#if defined(FILE_PATH_USES_DRIVE_LETTERS)
	return !EqualDriveLetterCaseInsensitive(this->path_, that.path_);
#else
	return path_ != that.path_;
#endif
}

const StringType& FilePath::strValue() const {
	return path_; 
}

const std::string FilePath::sstrValue() const {
#if defined(HERMAS_WIN)
	return WStringToString(path_);
#else
	return path_;
#endif
}

const CharType* FilePath::charValue() const { 
	return path_.c_str(); 
}

// static
bool FilePath::IsSeparator(CharType character) {
	for (size_t i = 0; i < sizeof(FilePath::kSeparators) - 1; ++i) {
		if (character == kSeparators[i]) {
			return true;
		}
	}
	return false;
}

// libgen's dirname and basename aren't guaranteed to be thread-safe and aren't
// guaranteed to not modify their input strings, and in fact are implemented
// differently in this regard on different platforms.  Don't use them, but
// adhere to their behavior.
FilePath FilePath::DirName() const {
	FilePath new_path(path_);
	new_path.StripTrailingSeparatorsInternal();

	//需要保留驱动盘字符
	StringType::size_type letter = FindDriveLetter(new_path.path_);
	StringType::size_type last_separator = new_path.path_.find_last_of(kSeparators,
																	   StringType::npos,
																	   sizeof(kSeparators) - 1);
	if (last_separator == StringType::npos) {
		// path_在当前目录下
		new_path.path_.resize(letter + 1);
	} else if (last_separator == letter + 1) {
		// path_在根目录下
		new_path.path_.resize(letter + 2);
	} else if (last_separator == letter + 2 && IsSeparator(new_path.path_[letter + 1])) {
		// path_在"//"下（可能还有驱动字符）
		new_path.path_.resize(letter + 3);
	} else if (last_separator != 0) {
		// 其他情况，裁剪base_name
		new_path.path_.resize(last_separator);
	}

	new_path.StripTrailingSeparatorsInternal();
	if (!new_path.path_.length()) {
		new_path.path_ = kCurrentDirectory;
	}
	return new_path;
}

FilePath FilePath::FullBaseName() const {
	FilePath new_path(path_);
	new_path.StripTrailingSeparatorsInternal();
	// 驱动字符被删除
	StringType::size_type letter = FindDriveLetter(new_path.path_);
	if (letter != StringType::npos) {
		new_path.path_.erase(0, letter + 1);
	}
	// Keep everything after the final separator, but if the pathname is only
	// one character and it's a separator, leave it alone.
	StringType::size_type last_separator = new_path.path_.find_last_of(kSeparators,
																	   StringType::npos,
																	   1);
	if (last_separator != StringType::npos && last_separator < new_path.path_.length() - 1) {
		new_path.path_.erase(0, last_separator + 1);
	}
	return new_path;
}

FilePath FilePath::BaseName() const {
	FilePath new_path = FullBaseName();
	StringType extension = FinalExtension();
	new_path.path_ = new_path.path_.substr(0, new_path.path_.length() - extension.length());
	return new_path;
}

StringType FilePath::FinalExtension() const {
	StringType base(FullBaseName().strValue());
	// Special case "." and ".."
	if (base == FilePath::kCurrentDirectory || base == FilePath::kParentDirectory) {
		return StringType();
	}
	const StringType::size_type dot = base.rfind(FilePath::kExtensionSeparator);
	if (dot == StringType::npos) {
		return StringType();
	}
	return base.substr(dot, StringType::npos);
}

FilePath FilePath::RemoveFinalExtension() const {
	  StringType extension = FinalExtension();
	  if (FinalExtension().empty())
		return *this;
	  return FilePath(path_.substr(0, path_.size() - extension.size()));
}

FilePath FilePath::Append(const StringType& component) const {
	  const StringType* appended = &component;
	  StringType without_nuls;

	  StringType::size_type nul_pos = component.find(kStringTerminator);
	  if (nul_pos != StringType::npos) {
		without_nuls = component.substr(0, nul_pos);
		appended = &without_nuls;
	  }

	  if (path_.compare(kCurrentDirectory) == 0) {
		// Append normally doesn't do any normalization, but as a special case,
		// when appending to kCurrentDirectory, just return a new path for the
		// component argument.  Appending component to kCurrentDirectory would
		// serve no purpose other than needlessly lengthening the path, and
		// it's likely in practice to wind up with FilePath objects containing
		// only kCurrentDirectory when calling DirName on a single relative path
		// component.
		return FilePath(*appended);
	  }

	  FilePath new_path(path_);
	  new_path.StripTrailingSeparatorsInternal();

	  // Don't append a separator if the path is empty (indicating the current
	  // directory) or if the path component is empty (indicating nothing to
	  // append).
	  if (appended->length() > 0 && new_path.path_.length() > 0) {
		// Don't append a separator if the path still ends with a trailing
		// separator after stripping (indicating the root directory).
		if (!IsSeparator(new_path.path_[new_path.path_.length() - 1])) {
		  // Don't append a separator if the path is just a drive letter.
		  if (FindDriveLetter(new_path.path_) + 1 != new_path.path_.length()) {
			new_path.path_.append(1, kSeparators[0]);
		  }
		}
	  }

	  new_path.path_.append(*appended);
	  return new_path;
}

FilePath FilePath::Append(const FilePath& component) const {
	return Append(component.strValue());
}

#if defined(HERMAS_WIN)
FilePath FilePath::Append(const char* component) const {
	return Append(StringToWString(std::string(component)));
}
#endif

bool FilePath::IsAbsolute() const {
	return IsPathAbsolute(path_);
}

void FilePath::StripTrailingSeparatorsInternal() {
	// 如果没有盘符的话，start会是1，以免裁减
	// If there is no drive letter, start will be 1, which will prevent stripping
	// the leading separator if there is only one separator.  If there is a drive
	// letter, start will be set appropriately to prevent stripping the first
	// separator following the drive letter, if a separator immediately follows
	// the drive letter.
	StringType::size_type start = FindDriveLetter(path_) + 2;

	StringType::size_type last_stripped = StringType::npos;
	for (StringType::size_type pos = path_.length(); pos > start && IsSeparator(path_[pos - 1]); --pos) {
		// If the string only has two separators and they're at the beginning,
		// don't strip them, unless the string began with more than two separators.
		if (pos != start + 1 || last_stripped == start + 2 || !IsSeparator(path_[start - 1])) {
			path_.resize(pos - 1);
			last_stripped = pos;
		}
	}
}

}

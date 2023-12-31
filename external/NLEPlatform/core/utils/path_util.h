/*
 * path_util.h
 */

#ifndef _UTIL_PATH_UTIL_H_
#define _UTIL_PATH_UTIL_H_

#include <string>
#include <iostream>
#include "nle_export.h"

namespace cbox {

    using std::string;
    using std::ostream;
    using std::istream;

    NLE_EXPORT_METHOD bool create_directory(const char *pathname);

    NLE_EXPORT_METHOD bool is_absolute_path(const string &pathname);

    NLE_EXPORT_METHOD bool is_root_path(const string &pathname);

    NLE_EXPORT_METHOD bool exists(const string &pathname);

    NLE_EXPORT_METHOD string basename(const string &pathname);

    NLE_EXPORT_METHOD string basename(const string &pathname, const string &suffix);

    NLE_EXPORT_METHOD string dirname(const string &pathname);

    NLE_EXPORT_METHOD string extname(const string &pathname);

    NLE_EXPORT_METHOD long long filesize(const string &pathname);

    NLE_EXPORT_METHOD bool remove_file(const string &pathname);

    NLE_EXPORT_METHOD bool rename_file(const string &from, const string &to);

    NLE_EXPORT_METHOD bool is_dir(const std::string &path);

    NLE_EXPORT_METHOD bool is_file(const std::string &path);

#if 0
    class Path {
    public:
        // constructors/destructor
        Path();
        Path(const Path& path);
        Path(const string& path);
        Path(const char* path);
        Path(const Path& parent, const string& basename, const string& extension = "");

        template <class InputIterator>
        Path(InputIterator first, InputIterator last);

        ~Path();

        // assignments
        Path& operator=(const Path& path);
        Path& operator=(const string& path);
        Path& operator=(const char* path);

        template <class InputIterator>
        Path& assign(InputIterator first, InputIterator last);

        // observers

        // tests whether the file or directory denoted by this abstract pathname exists.
        bool exists() const;

        // tests whether the file denoted by this abstract pathname is a directory.
        bool isDirectory() const;

        // tests whether the file denoted by this abstract pathname is a regular file.
        bool isRegularFile() const;

        // tests whether the file denoted by this abstract pathname is neither a directory nor a regular file.
        bool isOther() const;

        // tests whether the file or directory denoted by this abstract pathname is empty.
        bool isEmpty() const;

        // tests whether the file or directory denoted by this abstract pathname is dot(".").
        bool isDot() const;

        // tests whether the file or directory denoted by this abstract pathname is dot-dot("..").
        bool isDotDot() const;

        // tests whether this abstract pathname is absolute.
        bool isAbsolute() const;

        // tests whether this abstract pathname is root.
        bool isRoot() const;

        // tests whether the application can read the file denoted by this abstract pathname.
        bool isReadable() const;

        // tests whether the application can write the file denoted by this abstract pathname.
        bool isWritable() const;

        // tests whether the file denoted by this abstract pathname is a executable file.
        bool isExecutable() const;

        // tests whether the file denoted by this abstract pathname is a hidden file.
        bool isHidden() const;

        bool hasExtension() const;
        bool hasFilename() const;
        bool hasParent() const;
        bool hasRoot() const;
        bool hasRootName() const;
        bool hasRootDirectory() const;

        string basename() const;
        string extension() const;
        string filename() const;
        string root() const;
        string rootName() const;
        string rootDirectory() const;
        string toString() const;

        // returns the time that the file denoted by this abstract pathname was last modified.
        time_t lastModified() const;

        // returns the length of the file(in bytes) denoted by this abstract pathname.
        size_t filesize() const;

        // returns the length of the pathname.
        size_t size() const;

        // returns the length of the pathname.
        size_t length() const;

        // tests whether this abstract pathname is empty.
        bool empty() const;

        Path parent() const;
        Path absolutize() const;
        Path relativize() const;
        Path relativize(const Path& path) const;

        // modifiers
        void clear();
        void swap(Path& rhs);
        Path& changeExtension(const string& extension);
        Path& compact(size_t length);
        Path& operator/=(const Path& rhs);

        template <class InputIterator>
        Path& append(InputIterator first, InputIterator last);

        Path& addSlash();
        Path& addExtension(const string& extension);

        Path& removeSlash();
        Path& removeExtension();

        Path& quoteSpaces();
        Path& unquoteSpaces();

        Path& removeFilename();

        // iterators
        class iterator;
        typedef iterator const_iterator;

        iterator begin() const;
        iterator end() const;

    public:
        static bool equivalent(const Path& lhs, const Path& rhs);
        static bool copy(const Path& src, const Path& dest);
        static bool createDirectory(const Path& path);
        static bool createDirectories(const Path& path);
        static bool remove(const Path& path);
        static bool removeAll(const Path& path);
        static bool rename(const Path& oldPath, const Path& newPath);
        static bool wildcardMatch(const string& pattern, const Path& path);
        static Path commonPrefix(const Path& lhs, const Path& rhs);
        static Path currentDirectory();
        static Path setCurrentDirectory(const Path& path);

    public:
        // the system-dependent path-separator character, represented as a string for convenience.
        static const char* SEPARATOR;

        // the system-dependent path-separator character.
        static const char SEPARATOR_CHAR;

        // the system-dependent default name-separator character, represented as a string for convenience.
        static const char* PATH_SEPARATOR;

        // the system-dependent default name-separator character.
        static const char PATH_SEPARATOR_CHAR;

    private:
        Path& canonicalize();

    private:
        friend bool operator==(const Path& lhs, const Path& rhs);
        friend bool operator!=(const Path& lhs, const Path& rhs);
        friend bool operator<(const Path& lhs, const Path& rhs);
        friend bool operator>(const Path& lhs, const Path& rhs);
        friend bool operator<=(const Path& lhs, const Path& rhs);
        friend bool operator>=(const Path& lhs, const Path& rhs);
        friend ostream& operator<<(ostream& out, const Path& path);
        friend istream& operator>>(istream& in, Path& path);

    private:
        string pathname_;
    };


    inline Path operator/(const Path& lhs, const Path& rhs) {
        Path temp(lhs);
        return temp /= rhs;
    }

    inline bool operator==(const Path& lhs, const Path& rhs) {
        return lhs.pathname_ == rhs.pathname_;
    }

    inline bool operator!=(const Path& lhs, const Path& rhs) {
        return lhs.pathname_ != rhs.pathname_;
    }

    inline bool operator<(const Path& lhs, const Path& rhs) {
        return lhs.pathname_ < rhs.pathname_;
    }

    inline bool operator>(const Path& lhs, const Path& rhs) {
        return lhs.pathname_ > rhs.pathname_;
    }

    inline bool operator<=(const Path& lhs, const Path& rhs) {
        return lhs.pathname_ <= rhs.pathname_;
    }

    inline bool operator>=(const Path& lhs, const Path& rhs) {
        return lhs.pathname_ >= rhs.pathname_;
    }

    inline ostream& operator<<(ostream& out, const Path& path) {
        return out << path.pathname_;
    }

    inline istream& operator>>(istream& in, Path& path) {
        return in >> path.pathname_;
    }
#endif

} //namespace cbox

#endif /* _UTIL_PATH_UTIL_H_ */

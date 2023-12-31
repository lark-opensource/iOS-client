// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_GENERATOR_VERSION_H_
#define LYNX_TASM_GENERATOR_VERSION_H_

#include <cstdio>
#include <iostream>
#include <string>

namespace lynx {
namespace tasm {

struct Version {
  int major = 0, minor = 0, revision = 0, build = 0;

  Version(const std::string& version) {
    std::sscanf(version.c_str(), "%d.%d.%d.%d", &major, &minor, &revision,
                &build);
    if (major < 0) major = 0;
    if (minor < 0) minor = 0;
    if (revision < 0) revision = 0;
    if (build < 0) build = 0;
  }

  bool operator<(const Version& other) const {
    // Compare major
    if (major < other.major)
      return true;
    else if (major > other.major)
      return false;

    // Compare moinor
    if (minor < other.minor)
      return true;
    else if (minor > other.minor)
      return false;

    // Compare revision
    if (revision < other.revision)
      return true;
    else if (revision > other.revision)
      return false;

    // Compare build
    if (build < other.build)
      return true;
    else if (build > other.build)
      return false;

    return false;
  }

  bool operator==(const Version& other) const {
    return major == other.major && minor == other.minor &&
           revision == other.revision && build == other.build;
  }

  bool operator>(const Version& other) const {
    if (*this == other) return false;
    return !(*this < other);
  }

  bool operator<=(const Version& other) const {
    if (*this == other) return true;
    return *this < other;
  }

  bool operator>=(const Version& other) const {
    if (*this == other) return true;
    return *this > other;
  }

  friend std::ostream& operator<<(std::ostream& stream, const Version& ver) {
    stream << ver.major;
    stream << '.';
    stream << ver.minor;
    stream << '.';
    stream << ver.revision;
    stream << '.';
    stream << ver.build;
    return stream;
  }
};

}  // namespace tasm
}  // namespace lynx
#endif  // LYNX_TASM_GENERATOR_VERSION_H_

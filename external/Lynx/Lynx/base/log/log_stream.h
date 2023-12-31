// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_LOG_LOG_STREAM_H_
#define LYNX_BASE_LOG_LOG_STREAM_H_

#include <atomic>
#include <cstdint>
#include <cstdlib>
#include <cstring>  // for function memcpy
#include <memory>
#include <sstream>
#include <string>

namespace lynx {
namespace base {
namespace logging {

constexpr int32_t kSmallBuffer = 4096;

// brief: store log messages from class Log Stream at stack
// Example:
//    MixBuffer buffer;
//    if (buffer.Available() > availbale_size ) {
//      buffer.Append(source, sizeof(source));
//    }
// 1、 Available() have a out of boundary check
// 2、 Reset() writes at the begin of stack buffer
// 3、 CLear() emptys the stack buffer
class MixBuffer {
 public:
  MixBuffer() : current_(data_) {}

  // uncopyable
  MixBuffer(const MixBuffer&) = delete;
  void operator=(const MixBuffer&) = delete;

  void Append(const char* buffer, size_t length) {
    if (static_cast<size_t>(Available()) > length) {
      memcpy(current_, buffer, length);
      AddLength(length);
    }
  }

  const char* Data() const { return data_; }
  int32_t Length() const { return static_cast<int32_t>(current_ - data_); }

  char* Current() { return current_; }
  int32_t Available() const { return static_cast<int32_t>(End() - current_); }
  // write at begin of stach buffer
  void Reset() { current_ = data_; }
  // Empty the stack buffer
  void Clear() {
    memset(data_, 0, sizeof(data_));
    Reset();
  }

 private:
  void AddLength(size_t length) {
    current_ += length;
    *current_ = '\0';
  }
  const char* End() const { return data_ + sizeof(data_); }
  // when buffer size is longer than 4096 bytes(kSmallBuffer), do nothing.such
  //    as ALog limits size to 4096 bytes
  char data_[kSmallBuffer];
  char* current_;
};

// brief: Replace std::iostream with class LogStream, overwrite operator<< for
// base types, include: bool, char, int, int64, size_t, void*, float, double,
// string, ostream, ostringstream In case of int, double, char*, address type,
// It is faster and faster than snprintf and std::ostream Example:
//    LogStream os;
//    os << 2022 << "-" << 9 << "-" << 5 << "  " << "Welcome to the world of
//    lynx"; std::cout << os.str() << std::endl;
// !!!!!  Notice  !!!!!
// 1、class LogStream don`t support format string, such as std::hex,
//    std::setfill, std::setw. but you can do like this:
//        std::ostringstream buf;
//        LogStream os;
//        buf << std::setfill('0') << std::setw(10) << 123456;
//        os << buf;
// 2、when buffer size is longer than 4096 bytes(kSmallBuffer), do nothing.such
//    as ALog limits size to 4096 bytes
// 3、when convert address to hex string,
//    . if nullptr, the output is 0x00000000 in 32bits OS
//      and 0x0000000000000000 in 64bits OS
//    . have a fixed length output
// 4、 convert const char * to string
//    if nullptr, the output will be truncated

class LogStream {
 public:
  LogStream() = default;
  ~LogStream() = default;

  // uncopyable
  LogStream(const LogStream&) = delete;
  void operator=(const LogStream&) = delete;

  LogStream& operator<<(bool);

  /**
   * replace snprintf with Milo based on branchlut scheme.[Written by Milo
   * Yip][Designed by Wojciech Muła] about 25x speedup faster than snprintf
   */
  // integer
  LogStream& operator<<(int8_t);
  LogStream& operator<<(uint8_t);
  LogStream& operator<<(int16_t);
  LogStream& operator<<(uint16_t);
  LogStream& operator<<(int32_t);
  LogStream& operator<<(uint32_t);
  LogStream& operator<<(int64_t);
  LogStream& operator<<(uint64_t);

// int64_t has different definition
// long long in 32bits while long in 64bits Android and linux
// long long in 64bits MacOS, iOS, Windows
#if defined(__LP64__) && (defined(OS_ANDROID) || defined(__linux__))
  LogStream& operator<<(long long value) {
    return operator<<(static_cast<int64_t>(value));
  }
  LogStream& operator<<(unsigned long long value) {
    return operator<<(static_cast<uint64_t>(value));
  }
#else
  LogStream& operator<<(long value) {
    return operator<<(static_cast<int64_t>(value));
  }
  LogStream& operator<<(unsigned long value) {
    return operator<<(static_cast<uint64_t>(value));
  }
#endif

  LogStream& operator<<(const void*);

  /**
   * replace snprintf with Milo based on Grisu2.[Written by Milo Yip][Designed
   * by Florian Loitsch] about 9x speedup faster than snprintf 15 precision
   * default
   */
  // TODO(lipin): overload float func with precision
  LogStream& operator<<(float);
  LogStream& operator<<(double);

  LogStream& operator<<(const char&);

  LogStream& operator<<(const char*);
  LogStream& operator<<(const unsigned char* value) {
    return operator<<(reinterpret_cast<const char*>(value));
  }

  LogStream& operator<<(const std::string&);
  LogStream& operator<<(const std::string_view&);

  // overload for wchar_t, std::wstring
#if defined(OS_WIN)
  LogStream& operator<<(wchar_t value);
  LogStream& operator<<(const wchar_t* value);
  LogStream& operator<<(const std::wstring& value);
  LogStream& operator<<(const std::wstring_view& value);
#endif

  // operator for std::ostream
  LogStream& operator<<(const std::ostringstream& output) {
    return operator<<(output.str());
  }

  friend std::ostream& operator<<(std::ostream& output,
                                  const LogStream& message) {
    output << message.c_str();
    return output;
  }

  LogStream& operator<<(const LogStream& output) {
    Append(output.c_str(), output.Buffer().Length());
    return *this;
  }

  // overload for std::shared_ptr
  template <typename T>
  LogStream& operator<<(const std::shared_ptr<T>& value) {
    return operator<<(value.get());
  }

  // overload for std::unique_ptr
  template <typename T>
  LogStream& operator<<(const std::unique_ptr<T>& value) {
    return operator<<(value.get());
  }

  // overload for std::weak_ptr
  template <typename T>
  LogStream& operator<<(const std::weak_ptr<T>& value) {
    return operator<<(value.lock().get());
  }

  // overload for std::atomic
  // type which is not trivially copyable is not supported
  // support UDT which must be trivially copyable, such as:
  // class SelfType {
  //   double value_;
  //   public:
  //    explicit SelfType(double value) : value_(value) {}
  //    inline friend LogStream& operator<<(LogStream& output, const SelfType&
  //    input) {
  //     output << input.value_;
  //     return output;
  //    }
  // };

  template <typename T>
  LogStream& operator<<(const std::atomic<T>& value) {
    *this << value.load();
    return *this;
  }

  // overload for std::endl
  // Function implementation:
  // *
  //   template <class _CharT, class _Traits>
  //   inline _LIBCPP_INLINE_VISIBILITY
  //   basic_ostream<_CharT, _Traits>&
  //   endl(basic_ostream<_CharT, _Traits>& __os)
  //   {
  //       __os.put(__os.widen('\n'));
  //       __os.flush();
  //       return __os;
  //   }
  // *
  // !!!NOTICE: !!!
  // Need to distinguish the same implementation between std::endl, std::ends
  // and std::flush
  using CharT_ = char;
  using TraitsT_ = std::char_traits<CharT_>;
  LogStream& operator<<(std::basic_ostream<CharT_, TraitsT_>& (*function_endl)(
      std::basic_ostream<CharT_, TraitsT_>&)) {
    if (function_endl == std::endl<CharT_, TraitsT_>) {
#if defined(OS_WIN)
      return operator<<("\r\n");
#else
      return operator<<("\n");
#endif
    }
// for debug, if not std::endl, than abort
// for release, do nothing
#ifndef NDEBUG
    else {
      // only support type std::endl;
      // you need to overload opertator<< for UDT
      abort();
    }
#endif
    return *this;
  }

  void Append(const char* buffer, size_t length) {
    buffer_.Append(buffer, length);
  }
  const MixBuffer& Buffer() const { return buffer_; }
  const char* c_str() const { return buffer_.Data(); }
  std::string str() const { return std::string(buffer_.Data()); }
  void Reset() { buffer_.Reset(); }
  void Clear() { buffer_.Clear(); }

 private:
  MixBuffer buffer_;
};
}  // namespace logging
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_LOG_LOG_STREAM_H_

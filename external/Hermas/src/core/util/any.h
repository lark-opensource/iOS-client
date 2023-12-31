//
// Created by xuzhi on 2021/7/12.
//

#ifndef HERMAS_ANY_H
#define HERMAS_ANY_H

#include <memory>
#include <string>

namespace hermas {
    namespace util {
        /**
         * @brief Simple impl of Any in C++17
         * Why we do not use absl::any?
         * Because we have a lot of shared_ptr and pointer data in our code.
         * If we use absl::any, the code will be almost unreadable for most people.
        */
class Any {
        public:
            /**
             * @brief Default C'str
            */
            Any() = default;
            ~Any() = default;

            /**
             * @brief Default copy and move
            */
            Any(const Any& r) : data_(r.data_) {}
            Any(std::nullptr_t null) : data_(nullptr) {}
            Any(Any&& r) : data_(std::move(r.data_)) {}

            Any& operator = (const Any& r) {
                if ( this == &r ) return *this;
                data_ = r.data_;
                return *this;
            }

            Any& operator = (Any&& r) {
                if ( this == &r ) return *this;
                data_ = std::move(r.data_);
                return *this;
            }

            /**
             * @brief Create instance with any target
            */
            template <
                    typename T,
                    typename std::enable_if<
                            !std::is_same<typename std::decay<T>::type, Any>::value &&
                            !std::is_same<typename std::decay<T>::type, std::nullptr_t>::value,
                            int
                    >::type = 0
            > Any(const T& t) {
                std::shared_ptr<T> pt = std::make_shared<T>(t);
                data_ = std::static_pointer_cast<void>(pt);
            }
            template <
                    typename T,
                    typename std::enable_if<
                            !std::is_same<typename std::decay<T>::type, Any>::value,
                            int
                    >::type = 0
            > Any(typename std::decay<T>::type && t) {
                std::shared_ptr<T> pt = std::make_shared<T>(std::move(t));
                data_ = std::static_pointer_cast<void>(pt);
            }
            template <
                    template <class> class _Container,
                    typename T,
                    typename std::enable_if<
                            std::is_same< _Container<T>, std::shared_ptr<T> >::value, int
            >::type = 0
            > Any(_Container<T> ptr) {
                data_ = std::static_pointer_cast<void>(ptr);
            }
            template <
                    template <class> class _Container,
                    typename T,
                    typename std::enable_if<
                            std::is_same< _Container<T>, std::shared_ptr<T> >::value, int
            >::type = 0
            > Any(_Container<T>&& ptr) {
                auto p = std::move(ptr);
                data_ = std::static_pointer_cast<void>(p);
            }

            /**
             * @brief Create instance from pointer
            */
            template <typename T>
            Any(const T* t, bool copy = false) {
                if ( t == nullptr ) return;
                if ( copy ) {
                    std::shared_ptr<T> pt = std::make_shared<T>(*t);
                    data_ = std::static_pointer_cast<void>(pt);
                } else {
                    T* lt = const_cast<T*>(t);
                    std::shared_ptr<T> pt(lt, [](auto p) {});
                    data_ = std::static_pointer_cast<void>(pt);
                }
            }

            /**
             * @brief Specifial for const char *
            */
            Any(const char* str) {
                std::shared_ptr<std::string> pstr = std::make_shared<std::string>(str);
                data_ = std::static_pointer_cast<void>(pstr);
            }

            /**
             * @brief Assign and move direct from value
            */
            template <
                    typename T,
                    typename std::enable_if<
                            !std::is_same<typename std::decay<T>::type, Any>::value &&
                            !std::is_same<typename std::decay<T>::type, std::nullptr_t>::value,
                            int
                    >::type = 0
            > Any& operator = (const T& t) {
                Any a(t);
                data_ = a.data_;
                return *this;
            }

            Any& operator = (std::nullptr_t null) {
                data_ = nullptr;
                return *this;
            }

            template <
                    typename T,
                    typename std::enable_if<
                            !std::is_same<typename std::decay<T>::type, Any>::value,
                            int
                    >::type = 0
            > Any& operator = (typename std::decay<T>::type&& t) {
                Any a(std::move(t));
                data_ = a.data_;
                return *this;
            }

            template <
                    template <class> class _Container,
                    typename T,
                    typename std::enable_if<
                            std::is_same< _Container<T>, std::shared_ptr<T> >::value, int
            >::type = 0
            > Any& operator = (std::shared_ptr<T> t) {
                data_ = std::static_pointer_cast<void>(t);
                return *this;
            }

            template <typename T>
            Any& operator = (const T* t) {
                Any a(t, true);
                data_ = a.data_;
                return *this;
            }

            Any& operator = (const char* t) {
                Any a(t);
                data_ = a.data_;
                return *this;
            }

            bool operator == (const Any& t) {
                return data_ == t.data_;
            }
            bool operator != (const Any& t) {
                return data_ != t.data_;
            }

            template<typename T>
            bool operator == (const T* p) {
                return data_.get() == p;
            }
            template<typename T>
            bool operator != (const T* p) {
                return data_.get() != p;
            }

            /**
             * @brief Bool cast
            */
            operator bool() {
                return data_ != nullptr;
            }

            /**
             * @brief Get the value
            */
            template <typename T>
            T& Cast() {
                return *std::static_pointer_cast<T>(data_);
            }

            template <typename T>
            const T& Cast() const {
                return *std::static_pointer_cast<T>(data_);
            }

            template <typename T>
            Any& Init(T* pt) {
                data_ = std::static_pointer_cast<void>(std::shared_ptr<T>(pt));
                return *this;
            }

            /**
             * @brief directly get data
            */
            template <typename T>
            std::shared_ptr<T> Data() {
                return std::static_pointer_cast<T>(data_);
            }

            /**
             * @brief Reset the value
            */
            void Clear() {
                data_.reset();
            }

            /**
             * @brief Check if any contains value
            */
            bool HasValue() const {
                return (data_ != nullptr);
            }

        protected:
            std::shared_ptr<void>   data_;
        };
    }
}

#endif //HERMAS_ANY_H

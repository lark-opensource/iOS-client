// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_LYNX_ORDERED_MAP_H_
#define LYNX_BASE_LYNX_ORDERED_MAP_H_

#include <list>
#include <unordered_map>
#include <utility>

namespace lynx {

template <class Key, class T, class Hash = std::hash<Key>>
class lynx_ordered_map {
 public:
  using size_type = size_t;
  using value_type = std::pair<Key, T>;
  using reference = value_type&;
  using const_reference = const value_type&;
  using iterator = typename std::list<std::pair<Key, T>>::iterator;
  using const_iterator = typename std::list<std::pair<Key, T>>::const_iterator;

  lynx_ordered_map() = default;

  lynx_ordered_map(std::initializer_list<value_type> initial_list) {
    clear();
    for (auto value : initial_list) {
      list_.emplace_back(value);
      map_.insert({value.first, --list_.end()});
    }
  }

  lynx_ordered_map& operator=(const lynx_ordered_map& map) {
    clear();
    this->list_ = map.list_;
    for (auto it = this->list_.begin(); it != this->list_.end(); ++it) {
      this->map_.insert({it->first, it});
    }
    return *this;
  }

  lynx_ordered_map& operator=(lynx_ordered_map&& map) {
    clear();
    this->map_ = std::move(map.map_);
    this->list_ = std::move(map.list_);
    return *this;
  }

  lynx_ordered_map(const lynx_ordered_map& map) {
    this->list_ = map.list_;
    for (auto it = this->list_.begin(); it != this->list_.end(); ++it) {
      this->map_.insert({it->first, it});
    }
  }

  lynx_ordered_map(lynx_ordered_map&& map) {
    this->map_ = std::move(map.map_);
    this->list_ = std::move(map.list_);
  }

  void clear() noexcept {
    list_.clear();
    map_.clear();
  }

  iterator find(const Key& key) {
    auto iter = map_.find(key);
    if (iter != map_.end()) {
      return iter->second;
    }
    return list_.end();
  }

  const_iterator find(const Key& key) const noexcept {
    auto iter = map_.find(key);
    if (iter != map_.end()) {
      return iter->second;
    }
    return list_.end();
  }

  size_type erase(const Key& key) {
    auto it = map_.find(key);
    if (it != map_.end()) {
      list_.erase(it->second);
      map_.erase(it);
      return 1;
    }
    return 0;
  }

  iterator erase(iterator pos) { return erase(const_iterator(pos)); }

  /**
   * @copydoc erase(iterator pos)
   */
  iterator erase(const_iterator pos) {
    auto it = map_.find(pos->first);
    if (it != map_.end()) {
      auto iter = list_.erase(pos);
      map_.erase(it);
      return iter;
    }
    return list_.end();
  }

  const_iterator begin() const noexcept { return list_.begin(); }
  const_iterator end() const noexcept { return list_.end(); }
  iterator begin() noexcept { return list_.begin(); }
  iterator end() noexcept { return list_.end(); }

  const_reference front() const noexcept { return list_.front(); }
  reference front() noexcept { return list_.front(); }

  T& operator[](const Key& key) { return at(key); }

  T& operator[](Key&& key) { return at(key); }

  T& at(const Key& key) {
    if (!contains(key)) {
      value_type value = {key, T()};
      list_.emplace_back(value);
      map_.insert({key, --list_.end()});
    }
    return map_[key]->second;
  }

  bool contains(const Key& key) const {
    return map_.count(key) == 1 ? true : false;
  }

  std::pair<iterator, bool> insert(const value_type& value) {
    auto it = map_.find(value.first);
    if (it == map_.end()) {
      list_.emplace_back(value);
      map_.insert({value.first, --list_.end()});
      return std::make_pair(--list_.end(), true);
    } else {
      it->second->second = value.second;
      return std::make_pair(it->second, true);
    }
  }

  std::pair<iterator, bool> insert(value_type& value) { return insert(value); }

  template <class InputIt>
  void insert(InputIt first, InputIt last) {
    for (; first != last; ++first) {
      const value_type& value = *first;
      insert(value);
    }
  }

  std::pair<iterator, bool> insert_or_assign(const Key& k, const T& obj) {
    auto it = map_.find(k);
    if (it == map_.end()) {
      return insert({k, obj});
    } else {
      it->second->second = obj;
      return std::make_pair(it->second, true);
    }
  }

  std::pair<iterator, bool> emplace(const value_type& value) {
    return insert(value);
  }

  std::pair<iterator, bool> emplace(value_type&& value) {
    return insert(value);
  }

  bool empty() const noexcept { return map_.empty(); }

  void reserve(size_type count) { map_.reserve(count); }

  size_type size() const noexcept { return map_.size(); }
  float load_factor() const {
    if (list_.size() == 0) {
      return 0;
    }
    return float(size()) / float(list_.size());
  }

 private:
  std::list<std::pair<Key, T>> list_;
  std::unordered_map<Key, iterator> map_;
};
}  // end namespace lynx

#endif  // LYNX_BASE_LYNX_ORDERED_MAP_H_

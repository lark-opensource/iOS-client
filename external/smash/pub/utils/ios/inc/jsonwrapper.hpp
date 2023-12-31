#ifndef _SMASH_VIDEO_UTILS_CJSONPP_H
#define _SMASH_VIDEO_UTILS_CJSONPP_H

#include <set>
#include <stdexcept>
#include <stdint.h>
#include <string>
#include <map>
#include <vector>
#include <memory>
#include "tt_utils.h"

#include "smash_cJSON.h"

namespace smash {
namespace utils {
namespace jsonwrapper {
  // JSON type wrapper enum
  enum JSONType {
                 Invalid = cJSON_Invalid,
                 False = cJSON_False,
                 True = cJSON_True,
                 Null = cJSON_NULL,
                 Number = cJSON_Number,
                 String = cJSON_String,
                 Array = cJSON_Array,
                 Object = cJSON_Object,
                 Raw = cJSON_Raw,
                 IsReference = cJSON_IsReference,
                 StringIsConst = cJSON_StringIsConst,
  };

// Exception thrown in case of parse or value errors
  class JSONError : public std::runtime_error
  {
  public:
    explicit JSONError(const char* what)
      : std::runtime_error(what)
    {}
  };

  class JSONObject{
    // internal cJSON holder with ownership flag
    struct Holder
    {
      cJSON* o;
      bool own_;
      Holder(cJSON* obj, bool own)
        : o(obj)
        , own_(own)
      {
        LOGD("JSONObject Holder constructor\n");
      }
      ~Holder()
      {
        if (own_)
          cJSON_Delete(o);
      }

      inline cJSON* operator->() { return o; }

    private:
      // no copy constructor
      explicit Holder(const Holder&);

      // no assignment operator
      Holder& operator=(const Holder&);
    };
    using HolderPtr = std::shared_ptr<Holder>;
    using ObjectSet = std::set<JSONObject>;
    using ObjectSetPtr = std::shared_ptr<ObjectSet>;
    // get value (specialized below)
    template <typename T>
    T as(cJSON* obj) const;
    HolderPtr obj_;
    ObjectSetPtr refs_;

    class iterator
    {
    public:
      iterator(cJSON* ptr)
        : ptr(ptr)
      {}
      iterator operator++()
      {
        ptr = ptr->next;
        return *this;
      }
      bool operator!=(const iterator& other) const { return ptr != other.ptr; }
      const JSONObject operator*() const { return JSONObject(ptr,false); }

    private:
      cJSON* ptr;
    };

    static const std::map<JSONType, std::string> typeMap;

  public:
    ~JSONObject(){}
    inline cJSON* obj() const { return obj_->o; }
    iterator begin() const { return iterator(obj_->o->child); }
    iterator end() const { return iterator(nullptr); }

    // necessary for holding references in the set
    bool operator<(const JSONObject& other) const { return obj_->o < other.obj_->o; }


    // create empty object
    JSONObject() : obj_(new Holder(cJSON_CreateObject(), true)) , refs_(new ObjectSet) {}

    // wrap existing cJSON object
    JSONObject(cJSON* obj, bool own) {
      obj_ = std::make_shared<Holder>(obj, own);
      refs_ = std::make_shared<ObjectSet>();
      LOGD("JSONObject constructor\n");
    }

    // wrap existing cJSON object with parent
    JSONObject(JSONObject parent, cJSON* obj, bool own) : obj_(new Holder(obj, own)), refs_(new ObjectSet)
    {
      refs_->insert(parent);
    }

    // create boolean object
    explicit JSONObject(bool value) : obj_(new Holder(value ? cJSON_CreateTrue() : cJSON_CreateFalse(), true))
    {}

    // create double object
    explicit JSONObject(double value) : obj_(new Holder(cJSON_CreateNumber(value), true)) {}

    // create integer object
    explicit JSONObject(int value) : obj_(new Holder(cJSON_CreateNumber(static_cast<double>(value)), true)) {}

    // create integer object
    explicit JSONObject(int64_t value) : obj_(new Holder(cJSON_CreateNumber(static_cast<double>(value)), true)) {}

    // create string object
    explicit JSONObject(const char* value) : obj_(new Holder(cJSON_CreateString(value), true)) {}

    explicit JSONObject(const std::string& value) : obj_(new Holder(cJSON_CreateString(value.c_str()), true)) {}


    /////////////////////////
    // copy constructor
    /////////////////////////
    JSONObject(const JSONObject& other) : obj_(other.obj_) , refs_(other.refs_) {
      LOGD("JSONObject copy constructor\n");
    }

    // copy operator
    inline JSONObject& operator=(const JSONObject& other)
    {
      LOGD("JSONObject operator= \n");
      if (&other != this) {
        obj_ = other.obj_;
        refs_ = other.refs_;
      }
      return *this;
    }

    // get object type
    inline JSONType type() const { return static_cast<JSONType>((*obj_)->type); }

    inline std::string typeName() const { return typeMap.at(type()); }

    inline bool IsBool() const { return type() == True || type() == False; }

    inline bool IsNumber() const { return type() == Number; }

    inline bool IsObject() const { return type() == Object || isReference(); }

    inline bool isReference() const { return type() & cJSON_IsReference; }

    inline bool IsArray() const { return type() == Array || isReference(); }

    inline bool IsString() const { return type() == String; }

    inline bool IsType(const std::string& type) const {
      if(type == "object")
        return IsObject();
      if (type == "array")
        return IsArray();
      if (type == "string")
        return IsString();
      if (type == "number")
        return IsNumber();
      if (type == "bool")
        return IsBool();
      return false;
    }

    inline int Size() const
    {
      if (obj_->o == nullptr)
        return 0;
      if (cJSON_IsNull(obj_->o))
        return 0;
      if (cJSON_IsArray(obj_->o))
        return cJSON_GetArraySize(obj_->o);
      if (cJSON_IsObject(obj_->o))
        return cJSON_GetArraySize(obj_->o);
      return 0;
    }

    inline std::string Getkey() const
    {
      if (obj_->o->string != nullptr)
        return std::string(obj_->o->string);
      else {
        throw JSONError("key is null");
      }
    }

    std::string Print(bool formatted = true) const
    {
      char* j = formatted ? cJSON_Print(obj_->o) : cJSON_PrintUnformatted(obj_->o);
      std::string retval(j);
      free(j);
      return retval;
    }

    // get value from this object
    template <typename T>
    inline T as() const
    {
      return as<T>(obj_->o);
    }

    // get array
    template <typename T = JSONObject, template <typename X, typename A> class ContT = std::vector>
    inline ContT<T, std::allocator<T>> asArray() const
    {
      if (((*obj_)->type) != cJSON_Array)
        throw JSONError("Not an array type");
      ContT<T, std::allocator<T>> retval;
      for (int i = 0; i < cJSON_GetArraySize(obj_->o); i++)
        retval.push_back(as<T>(cJSON_GetArrayItem(obj_->o, i)));
      return retval;
    }

    // get set
    template <typename T = JSONObject>
    inline std::set<T> asSet() const
    {
      if (((*obj_)->type) != cJSON_Array)
        throw JSONError("Not an array type");
      std::set<T> retval;
      for (int i = 0; i < cJSON_GetArraySize(obj_->o); i++)
        retval.insert(as<T>(cJSON_GetArrayItem(obj_->o, i)));
      return retval;
    }

    ///////////////////////////////
    // check if key exists
    ///////////////////////////////
    inline bool Has(const char* name) const { return cJSON_GetObjectItem(obj_->o, name) != nullptr; }
    inline bool Has(const std::string& name) const { return Has(name.c_str()); }

    ///////////////////////////////
    // get object by name
    ///////////////////////////////
    template <typename T = JSONObject>
    inline T Get(const char* name) const
    {
      if (!IsObject() && !isReference())
        throw JSONError("Not an object");
      cJSON* item = cJSON_GetObjectItem(obj_->o, name);
      if (item != nullptr)
        return as<T>(item);
      else
        throw JSONError("No such item");
    }

    JSONObject operator[](const std::string& key) const { return Get<JSONObject>(key); }

    JSONObject operator[](int idx) const { return Get<JSONObject>(idx); }

    template <typename T = JSONObject>
    inline JSONObject Get(const std::string& value) const
    {
      return Get<T>(value.c_str());
    }

    // get value from array
    template <typename T = JSONObject>
    inline T Get(int index) const
    {
      if (!IsArray())
        throw JSONError("Not an array type");

      cJSON* item = cJSON_GetArrayItem(obj_->o, index);
      if (item != nullptr)
        return as<T>(item);
      else
        throw JSONError("No such item");
    }

    // set value in object
    template <typename T>
    inline void Set(const char* name, const T& value)
    {
      if (!IsObject())
        throw JSONError("Not an object type");
      JSONObject o(value);
      cJSON_AddItemReferenceToObject(obj_->o, name, o.obj_->o);
      refs_->insert(o);
    }

    // set value in object
    template <typename T>
    inline void Set(const std::string& name, const T& value)
    {
      Set(name.c_str(), value);
    }

    // set value in object (std::string)
    inline void Set(const std::string& name, const JSONObject& value) { return Set(name.c_str(), value); }
  };

  // parse from C string
  inline JSONObject Parse(const char* str)
  {
    cJSON* cjson = cJSON_Parse(str);
    if (cjson)
      return JSONObject(cjson, true);
    else
      throw JSONError("Parse error");
  }

  // parse from C string
  inline JSONObject Parse(const char* str, bool require_null_terminated)
  {
    cJSON* cjson = cJSON_ParseWithOpts(str, nullptr, require_null_terminated);
    if (cjson){
      return JSONObject(cjson, true);
    } else
      throw JSONError("Parse error");
  }

  // parse from std::string
  inline JSONObject Parse(const std::string& str)
  {
    return Parse(str.c_str());
  }

  // create null object
  inline JSONObject NullObject()
  {
    return JSONObject(cJSON_CreateNull(), true);
  }


// Specialized getters
template <>
inline int JSONObject::as<int>(cJSON* obj) const
{
	if ((obj->type) != cJSON_Number)
		throw JSONError("Bad value type");
	return obj->valueint;
}

template <>
inline int64_t JSONObject::as<int64_t>(cJSON* obj) const
{
	if ((obj->type) != cJSON_Number)
		throw JSONError("Not a number type");
	return static_cast<int64_t>(obj->valuedouble);
}

template <>
inline std::string JSONObject::as<std::string>(cJSON* obj) const
{
	if ((obj->type) != cJSON_String)
		throw JSONError("Not a string type");
	return obj->valuestring;
}

template <>
inline double JSONObject::as<double>(cJSON* obj) const
{
	if ((obj->type) != cJSON_Number)
		throw JSONError("Not a number type");
	return obj->valuedouble;
}

template <>
inline float JSONObject::as<float>(cJSON* obj) const
{
  if ((obj->type) != cJSON_Number)
    throw JSONError("Not a number type");
  return obj->valuedouble;
}

template <>
inline bool JSONObject::as<bool>(cJSON* obj) const
{
	if ((obj->type) == cJSON_True)
		return true;
	else if ((obj->type) == cJSON_False)
		return false;
	else
		throw JSONError("Not a boolean type");
}

template <>
inline JSONObject JSONObject::as<JSONObject>(cJSON* obj) const
{
	return JSONObject(*this, obj, false);
}

} // namespace jsonwrapper
} // namespace utils
}; // namespace smash

#endif

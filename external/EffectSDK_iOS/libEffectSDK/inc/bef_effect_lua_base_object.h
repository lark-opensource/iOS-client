
#ifndef bef_effect_lua_base_object_h
#define bef_effect_lua_base_object_h

#ifdef __cplusplus

constexpr size_t BEFRecursiveHash(char const * str, size_t seed)
{
   return 0 == *str ? seed : BEFRecursiveHash(str + 1, seed ^ (*str + 0x9e3779b9 + (seed << 6) + (seed >> 2)));
}

#define STR_HASH(x) (BEFRecursiveHash(x, 0))


#define CLASS_NAME_GETTER(classNameMark)\
public:\
size_t GetClassNameHash() const override {\
static_assert(std::is_class<classNameMark>::value,#classNameMark);\
    return classNameHash;\
}\
static const size_t classNameHash = STR_HASH(#classNameMark);\


#define CLASS_NAME_DEFINE_OVERRIDE(className) \
public:\
static_assert(std::is_class<className>::value,#className);\
virtual const char* getClassName() override {\
const static char* classNamePtr = #className;\
return classNamePtr;\
}

#define OBJECT_DEFINE(className,baseClass)\
static_assert(std::is_class<baseClass>::value,#baseClass);\
CLASS_NAME_GETTER(className)\
CLASS_NAME_DEFINE_OVERRIDE(className)\
className* getClassPtr() override {return this;}
class BaseLuaObject
{
public:
    virtual const char* getClassName() {
        static const char* className = "BaseLuaObject";
        return className;
    }
    virtual BaseLuaObject* getClassPtr() {return this;}
    virtual size_t GetClassNameHash() const {
        return classNameHash;
    }
    static constexpr const size_t classNameHash = STR_HASH("BaseLuaObject");
    template<class T>
    T* as()
    {
        if (T::classNameHash == GetClassNameHash())
        {
            return static_cast<T*>(this);
        }
        return nullptr;
    }
public:
    virtual ~BaseLuaObject(){}
};

#endif // __cplusplus

#endif


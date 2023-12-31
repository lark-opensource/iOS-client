//
// Created by bytedance on 2020/6/7.
//

#ifndef NLEPLATFORM_NLENODE_H
#define NLEPLATFORM_NLENODE_H

#include "nle_export.h"
#include "NLEResType.h"
#include "NLENodeMacro.h"
#include "NLEError.h"
#include "NLEFeature.h"
#include "NLELogger.h"
//#include "NLEAnimationType.h"
#include "NLENodeChangeInfo.h"
#include "json_forward.hpp"

#include <string>
#include <memory>
#include <utility>
#include <vector>
#include <algorithm>
#include <unordered_set>
#include <map>
#include <mutex>


#ifndef NLENODE_RTTI_DECLARE
#define NLENODE_RTTI_DECLARE(__CLASS_NAME)                                      \
    public:                                                                     \
    virtual std::string getClassName() const { return #__CLASS_NAME; }          \
    static std::string getStaticClassName() { return #__CLASS_NAME; }
#endif

#ifndef NLENODE_RTTI_GROUP
#define NLENODE_RTTI_GROUP(__CLASS_NAME)                                                              \
private:                                                                                        \
    static __CLASS_NAME* _create() { return new __CLASS_NAME(); }                               \
public:                                                                                         \
    static std::shared_ptr<__CLASS_NAME> dynamicCast(const std::shared_ptr<cut::model::NLENode>& node) {      \
        return std::dynamic_pointer_cast<__CLASS_NAME>(node);                                   \
    }                                                                                           \
    static std::string getStaticClassName() { return #__CLASS_NAME; }                           \
    std::string getClassName() const override { return #__CLASS_NAME; }                         \
    NLENode* clone() const override {                                                      \
        auto* newObj = new __CLASS_NAME();                                                      \
        *newObj = *this;                                                                        \
        return newObj;                                                                          \
    }
#endif // !NLENODE_RTTI_GROUP

#ifndef NLENODE_RTTI
#define NLENODE_RTTI(__CLASS_NAME)                                                              \
private:                                                                                        \
    static __CLASS_NAME* _create() { return new __CLASS_NAME(); }                               \
public:                                                                                         \
    static std::shared_ptr<__CLASS_NAME> dynamicCast(const std::shared_ptr<cut::model::NLENode>& node) {      \
        return std::dynamic_pointer_cast<__CLASS_NAME>(node);                                   \
    }                                                                                           \
    static std::string getStaticClassName() { return #__CLASS_NAME; }                           \
    static void registerCreateFunc() {                                                          \
        NLENodeDecoder::get()->registerCreateFunc(#__CLASS_NAME, _create);                      \
    }                                                                                           \
    std::string getClassName() const override { return #__CLASS_NAME; }                         \
    NLENode * clone() const override {                                                      \
        auto* newObj = new __CLASS_NAME();                                                      \
        *newObj = *this;                                                                        \
        return newObj;                                                                          \
    }
#endif // !NLENODE_RTTI

// https://gcc.gnu.org/wiki/VerboseDiagnostics#missing_vtable
#define KEY_FUNCTION_DEC_OVERRIDE(__CLASS) public: virtual void __key_function_() const override;
#define KEY_FUNCTION_DEC(__CLASS) public: virtual void __key_function_() const;
#define KEY_FUNCTION_IMP(__CLASS) void __CLASS::__key_function_() const {}

#define NLE_PROPERTY_DEC(__CLASS, __NAME, __TYPE, __VALUE, __FEATURE)                       \
private:                                                                                    \
    static const NLEValueProperty<__TYPE>& __P_##__NAME() {                                 \
        static const NLEValueProperty<__TYPE> one = {#__NAME, __VALUE, __FEATURE};          \
        return one;                                                                         \
    }                                                                                       \
public:                                                                                     \
    bool has##__NAME() const;                                                               \
    virtual void set##__NAME(const __TYPE& value);                                          \
    virtual __TYPE get##__NAME() const;

#define NLE_PROPERTY_DEC_FORCE_SET(__CLASS, __NAME, __TYPE, __VALUE, __FEATURE)             \
public:                                                                                     \
    virtual void forceSet##__NAME(const __TYPE& value);

#define NLE_PROPERTY_DEC_READONLY(__CLASS, __NAME, __TYPE, __VALUE, __FEATURE)              \
public:                                                                                     \
    virtual __TYPE get##__NAME() const;                                                     \
    bool has##__NAME() const;                                                               \
private:                                                                                    \
    virtual void set##__NAME(const __TYPE& value);                                          \
    static const NLEValueProperty<__TYPE>& __P_##__NAME() {                                 \
        static const NLEValueProperty<__TYPE> one = {#__NAME, __VALUE, __FEATURE};          \
        return one;                                                                         \
    }

#define NLE_PROPERTY_IMP_SET(__CLASS, __NAME, __TYPE, __VALUE)                   \
void __CLASS::set##__NAME(const __TYPE &value) {                                            \
    auto& property = __P_##__NAME();                                                        \
    NLEPropertyUtil::setValueInternal<__TYPE>(primaryValues, property, changeBits, featureList, listeners, value); \
}

#define NLE_PROPERTY_IMP_FORCE_SET(__CLASS, __NAME, __TYPE, __VALUE)             \
void __CLASS::forceSet##__NAME(const __TYPE &value) {                                       \
    auto& property = __P_##__NAME();                                                        \
    (*primaryValues)[property.name] = value;                                                \
    changeBits.markChange(ChangeBit::PROPERTY);                                             \
    featureList.insert(property.apiFeature);                                                \
                                                                                            \
    for (auto& listener : listeners) {                                                      \
        listener->onChanged();                                                              \
    }                                                                                       \
}

#define NLE_PROPERTY_IMP_GET(__CLASS, __NAME, __TYPE, __VALUE)                   \
__TYPE __CLASS::get##__NAME() const {                                                       \
    auto& property = __P_##__NAME();                                                        \
    return NLEPropertyUtil::getValueInternal<__TYPE>(primaryValues, property, property.defaultValue); \
}

#define NLE_PROPERTY_IMP_HAS(__CLASS, __NAME, __TYPE, __VALUE)                   \
bool __CLASS::has##__NAME() const {                                                         \
    return primaryValues->find(__P_##__NAME().name) != primaryValues->end();                \
}

#define NLE_PROPERTY_IMP(__CLASS, __NAME, __TYPE, __VALUE)                       \
NLE_PROPERTY_IMP_SET(__CLASS, __NAME, __TYPE, __VALUE)                           \
NLE_PROPERTY_IMP_GET(__CLASS, __NAME, __TYPE, __VALUE)                           \
NLE_PROPERTY_IMP_HAS(__CLASS, __NAME, __TYPE, __VALUE)

// 对象成员
#ifndef NLE_PROPERTY_OBJECT
#define NLE_PROPERTY_OBJECT(__CLASS, __NAME, __TYPE, __FEATURE)                             \
private:                                                                                    \
    static const NLEObjectProperty & _P_##__NAME() {                                        \
        static const NLEObjectProperty __P_##__NAME = {#__NAME, __FEATURE};                 \
        return __P_##__NAME;                                                                \
    }                                                                                       \
public:                                                                                     \
    virtual void set##__NAME(const std::shared_ptr<__TYPE>& object) {                       \
        setObject(_P_##__NAME(), object);                                                   \
    }                                                                                       \
    virtual std::shared_ptr<__TYPE> get##__NAME() const {                                   \
        return std::dynamic_pointer_cast<__TYPE>(getObject(_P_##__NAME().name));     \
    }
#endif // !NLE_PROPERTY_OBJECT_DEC

// 对象列表成员
#ifndef NLE_PROPERTY_OBJECT_LIST
#define NLE_PROPERTY_OBJECT_LIST(__CLASS, __NAME, __TYPE, __FEATURE)                \
private:                                                                            \
    static const NLEObjectListProperty & _P_##__NAME() {                            \
        static const NLEObjectListProperty __P_##__NAME = {#__NAME, __FEATURE};     \
        return __P_##__NAME;                                                        \
    }                                                                               \
public:                                                                             \
    virtual void add##__NAME(const std::shared_ptr<__TYPE>& child) {                \
        NLE_ASSERT_NOT_NULL(child);                                                 \
        addChild(_P_##__NAME(), child);                                             \
    }                                                                               \
    virtual bool remove##__NAME(const std::shared_ptr<__TYPE>& child) {             \
        return removeChild(_P_##__NAME().name, child);                              \
    }                                                                               \
    virtual void clear##__NAME() {                                                  \
        clearChildren(_P_##__NAME());                                               \
    }                                                                               \
    virtual std::vector<std::shared_ptr<__TYPE>> get##__NAME##s() const {           \
        std::vector<std::shared_ptr<__TYPE>> typeNodePtrVector;                     \
        auto nodePtrMap = getChildren(_P_##__NAME().name);                    \
        for (auto & nodePtrEntry : nodePtrMap) {                                                    \
            typeNodePtrVector.push_back(std::dynamic_pointer_cast<__TYPE>(nodePtrEntry.second));    \
        }                                                                                           \
        return typeNodePtrVector;                                                                   \
    }
#endif // !NLE_PROPERTY_OBJECT_LIST

#define NLE_KEY_AUTHOR "_author"
#define NLE_KEY_EXTRAS "_extras"

#define NLE_KEY_FEATURE "_features"
#define NLE_KEY_CLASS "_class"
#define NLE_KEY_OBJECTS "_objects"
#define NLE_KEY_BRANCH "_branch"

#define NLENODE_KEY_OBJECTS "_objects"
#define NLENODE_KEY_ARRAYS "_arrays"
#define NLENODE_KEY_EXTRAS "_extras"
#define NLENODE_KEY_FEATURE "_features"

namespace cut::model {

    class NLE_EXPORT_CLASS NLENode;
    class NLE_EXPORT_CLASS NLEResourceNode;

    using NLETime = int64_t; // 单位微秒 us
    static const NLETime NLETimeMax = 0x7FFFFFFFFFFFFFFF;
    using NLEVersion = int32_t;

    class NLE_EXPORT_CLASS NLEChangeListener {
    public:
        virtual ~NLEChangeListener() = default;
        virtual void onChanged() = 0;
    };

    class NLEPropertyBase {

    public:
        const std::string name;
        TNLEFeature const apiFeature;

        NLEPropertyBase(std::string name, TNLEFeature apiFeature)
                : name(std::move(name)), apiFeature(std::move(apiFeature)) {
        }

        bool operator==(const NLEPropertyBase &other) {
            return name == other.name;
        }
    };

    template<typename T>
    class NLEValueProperty : public NLEPropertyBase {

    public:
        const T defaultValue;

        NLEValueProperty(const std::string &name, T defaultValue, const TNLEFeature &apiFeature)
                : NLEPropertyBase(name, apiFeature), defaultValue(std::move(defaultValue)) {}
    };

    class NLEObjectProperty : public NLEPropertyBase {
    public:
        NLEObjectProperty(const std::string &name, const TNLEFeature &apiFeature)
                : NLEPropertyBase(name, apiFeature) {}
    };


    class NLEObjectListProperty : public NLEPropertyBase {
    public:
        NLEObjectListProperty(const std::string &name, const TNLEFeature &apiFeature)
                : NLEPropertyBase(name, apiFeature) {}
    };

    class NLE_EXPORT_CLASS SerialContext {
    public:
        SerialContext();

        SerialContext(std::shared_ptr<nlohmann::json> root);

        nlohmann::json &jsonRoot();

        nlohmann::json &jsonObjects();

        nlohmann::json &jsonFeatures();

        bool checkExist(const void *ptr) {
            auto ptrInt = reinterpret_cast<uint64_t>(ptr);
            return ptrToIdMap.find(ptrInt) != ptrToIdMap.end();
        }

        std::string obtainKey(const void *ptr) {
            auto ptrInt = reinterpret_cast<uint64_t>(ptr);
            auto entry = ptrToIdMap.find(ptrInt);
            if (entry != ptrToIdMap.end()) {
                return entry->second;
            }
            id++;
            auto idString = std::to_string(id);
            ptrToIdMap[ptrInt] = idString;
            return idString;
        }

    private:
        const std::shared_ptr<nlohmann::json> root;
        std::map<uint64_t, std::string> ptrToIdMap;
        uint64_t id;
    };

    class NLE_EXPORT_CLASS DeserialContext {
    public:
        DeserialContext(std::shared_ptr<const nlohmann::json> root);

        const nlohmann::json &jsonRoot() const;

        const nlohmann::json &jsonObjects() const;

        const nlohmann::json &jsonFeatures() const;

        bool checkExist(const std::string &id) const {
            return idToPtrMap.find(id) != idToPtrMap.end();
        }

        std::shared_ptr<NLENode> obtainPtr(const std::string &id, std::function<NLENode *()> creator) {
            auto entry = idToPtrMap.find(id);
            if (entry != idToPtrMap.end()) {
                // LOGGER->d("DeserialContext. re-use: id=[%s], ptr=[%p]", id.c_str(), entry->second.get());
                return entry->second;
            }
            auto ptr = creator();
            if (ptr) {
                std::shared_ptr<NLENode> sptr(ptr);
                idToPtrMap[id] = sptr;
                // LOGGER->d("DeserialContext. create: id=[%s], ptr=[%p]", id.c_str(), ptr);
                return sptr;
            } else {
                return std::shared_ptr<NLENode>(nullptr);
            }
        }

    private:
        const std::shared_ptr<const nlohmann::json> root;
        std::map<std::string, std::shared_ptr<NLENode>> idToPtrMap;
    };

    class NLE_EXPORT_CLASS NLENodeGroup;

    class NLE_EXPORT_CLASS NLENode {
        NLENODE_RTTI_DECLARE(NLENode);
        // 同个容器中，所有的 NLENode Name 唯一
        NLE_PROPERTY_DEC(NLENode, Name, std::string, "def", NLEFeature::E);
        // NLENode唯一标识，且草稿存盘恢复后保持不变
        NLE_PROPERTY_DEC_READONLY(NLENode, UUID, std::string, "def", NLEFeature::E);
        NLE_PROPERTY_DEC(NLENode, Enable, bool, true, NLEFeature::E);

        friend NLENodeGroup;

    public:

        virtual void __key_function_() const {
        }

        NLENode();
        NLENode(const NLENode& other) = delete;
        virtual ~NLENode() = default;

        // 浅拷贝
        NLENode &operator=(const NLENode &other);

        // 深对比
        bool equals(const std::shared_ptr<NLENode> &other) const;

        void collectResources(std::vector<std::shared_ptr<NLEResourceNode>>& resources) const;

        virtual NLEError writeToJson(SerialContext &context) const;

        virtual NLEError onWriteToJson(SerialContext &context, nlohmann::json &jsonObject) const;

        virtual NLEError onReadFromJson(DeserialContext &context, const nlohmann::json &jsonObject);

        // 参与草稿存盘/恢复
        const std::string &getExtra(const std::string &extraKey) const;

        std::vector<std::string> getExtraKeys();
        
        // 参与草稿存盘/恢复
        void setExtra(const std::string &extraKey, const std::string &inputExtra);

        void removeExtraWithKey(const std::string &extraKey);

        bool hasExtra(const std::string &extraKey) const;

        void clearExtra();

        // 不参与草稿存盘/恢复
        const std::string &getTransientExtra(const std::string &extraKey) const;

        // 不参与草稿存盘/恢复
        void setTransientExtra(const std::string &extraKey, const std::string &inputExtra);

        void removeTransientExtraWithKey(const std::string &extraKey);

        bool hasTransientExtra(const std::string &extraKey) const;

        void clearTransientExtra();

        /** readable string */
        virtual std::string toJsonString() const;

        /** Java 调试器 方便查看对象内容 */
        virtual std::string toString() const;

        virtual std::shared_ptr<nlohmann::json> toJson() const;

        virtual std::string hash() const;

        /** copy, create new one */
        virtual NLENode *clone() const = 0;

        /** deep clone ， id and name will be same */
        NLENode *deepClone() const;

        // shouldChangeId表示是否需要修改node对应的id和name信息
        // 若需要修改id和name信息就设置shouldChangeId为true
        NLENode *deepClone(const bool shouldChangeId) const;

        void cloneToNode(NLENode &desNode, const bool shouldChangeId) const;

        // 存储到 stage 区，并返回新的 stage 区对象
        virtual std::shared_ptr<NLENode> addToStage(int64_t version);

        // 用 stage 区的对象刷新 working 区
        virtual bool addToWorking(const std::shared_ptr<NLENode>& stageObject);

        bool isWorkingDirty() const;
        void clearWorkingDirty();
        cut::model::ChangeBits getWorkingDirty() const;

        void addListener(const std::shared_ptr<cut::model::NLEChangeListener>& listener) {
            listeners.push_back(listener);
        }

        void clearListener() {
            listeners.clear();
        }

        std::shared_ptr<NLENode> getStage() const {
            return stage;
        }
        std::string getStringId() const {
            return std::to_string(getId());
        }

        // 运行期 id，全局唯一
        int64_t getId() const {
            return reinterpret_cast<int64_t>(this);
        }

        virtual NLEClassType getClassType() const;

        /**
         * 以当前 NLENode 作为根节点/根路径，输入查找目标节点 NLENode，返回目标节点路径；
         * 假如查找不到输入的 NLENode，则返回空 ""
         * @param node
         * @return
         */
        // std::string getNodePath(const std::shared_ptr<const NLENode>& node) const;

        const std::map<std::string, std::shared_ptr<NLENode>>& getChildren() const;

    private:
        void setObject(const std::string &keyName, const std::shared_ptr<NLENode> &object);
        void addChild(const std::string &keyName, const std::shared_ptr<NLENode> &object);
        // 设置uuid和name
        void geneNameAndUUID( NLENode *node)  const;

    protected:
        // bool getNodePath(const std::string & parentPath, const NLENode * target, std::string & resultPath) const;

        // property is a NLENode object;
        void setObject(const NLEPropertyBase &key, const std::shared_ptr<NLENode> &object);
        std::shared_ptr<NLENode> getObject(const std::string &keyName) const;
        bool removeObject(const std::string &keyName);
        void clearObject();

        // property is a NLENodeGroup object;
        void addChild(const NLEPropertyBase &key, const std::shared_ptr<NLENode> &object);
        bool removeChild(const std::string &keyName, const std::shared_ptr<NLENode> &object);
        void clearChildren(const NLEPropertyBase &key);
        std::map<std::string, std::shared_ptr<NLENode>> getChildren(const std::string &keyName) const;

        ChangeBits changeBits;

        // store the primary property value; such as int, std::string
        std::shared_ptr<nlohmann::json> primaryValues;
        // store the primary list property value; such as list<int>, list<std::string>
        std::map<std::string, std::shared_ptr<nlohmann::json>> primaryListValues;
        // KEY: property name, VALUE: NLENode object
        std::map<std::string, std::shared_ptr<NLENode>> nleObjectMap;

        // KEY: extra key, VALUE: string extra value
        std::map<std::string, std::string> extraMap;
        // KEY: extra key, VALUE: string extra value
        std::map<std::string, std::string> transientExtraMap;

        std::unordered_set<TNLEFeature> featureList;

        std::vector<std::shared_ptr<NLEChangeListener>> listeners;

        std::shared_ptr<NLENode> stage;
    };

    class NLE_EXPORT_CLASS NLENodeGroup : public NLENode {
    NLENODE_RTTI_GROUP(NLENodeGroup);
    KEY_FUNCTION_DEC_OVERRIDE(NLESegmentMV)

        friend NLENode;

    private:
        uint32_t index = 0;

    public:

        NLENodeGroup() = default;
        NLENodeGroup(const NLENodeGroup& other) = delete;

        NLENodeGroup &operator=(const NLENodeGroup &other);

        bool addToWorking(const std::shared_ptr<NLENode>& stageObject) override;

        // 队尾添加
        void addObject(const std::shared_ptr<NLENode> &object);
        bool removeObject(const std::shared_ptr<NLENode> &object);
    };
}

#endif //NLEPLATFORM_NLENODE_H

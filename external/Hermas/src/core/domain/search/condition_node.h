//
//  condition_node.h
//  Hermas
//
//  Created by 崔晓兵 on 11/2/2022.
//

#ifndef search_condition_h
#define search_condition_h

#include <string>
#include <memory>
#include <vector>

#include "json.h"
#include "Any.h"

namespace Json { class Value; };

namespace hermas {

enum ConditionJudgeType {
    ConditionJudgeNone = 0,
    ConditionJudgeLess,
    ConditionJudgeEqual,
    ConditionJudgeGreater,
    ConditionJudgeContain,
    ConditionJudgeIsNULL,
};

// 这里使用组合模式解决条件查询的多样性和嵌套性

class ConditionNode : public std::enable_shared_from_this<ConditionNode> {
public:
    virtual ~ConditionNode() = default;
    bool Match(const std::string& json);
    void AddChildNode(const std::shared_ptr<ConditionNode>& child);
    void removeChildNode(const std::shared_ptr<ConditionNode>& child);
    
    virtual bool Match(const Json::Value& json) = 0;
    virtual bool Violate(const std::string& key, double threshold) = 0;
    virtual bool Violate(const std::string& key, const std::pair<double, double>& region) = 0;
    
    virtual std::shared_ptr<ConditionNode> Pruning(const std::string& key) = 0;
    
    std::map<std::string, util::Any> user_info;
protected:
    std::vector<std::shared_ptr<ConditionNode>> m_children;
};


class ConditionAndNode : public ConditionNode {
public:
    virtual bool Match(const Json::Value& data) override;
    virtual bool Violate(const std::string& key, double threshold) override;
    virtual bool Violate(const std::string& key, const std::pair<double, double>& region) override;
    virtual std::shared_ptr<ConditionNode> Pruning(const std::string& key) override;
};


class ConditionOrNode : public ConditionNode {
public:
    virtual bool Match(const Json::Value& data) override;
    virtual bool Violate(const std::string& key, double threshold) override;
    virtual bool Violate(const std::string& key, const std::pair<double, double>& region) override;
    virtual std::shared_ptr<ConditionNode> Pruning(const std::string& key) override;
};


class ConditionLeafNode : public ConditionNode {
public:
    ConditionLeafNode(ConditionJudgeType type, const std::string& key, double threshold, const std::string& string_value);
    virtual bool Match(const Json::Value& data) override;
    virtual bool Violate(const std::string& key, double threshold) override;
    virtual bool Violate(const std::string& key, const std::pair<double, double>& region) override;
    virtual std::shared_ptr<ConditionNode> Pruning(const std::string& key) override;
private:
    ConditionJudgeType m_judge_type;
    std::string m_key;
    std::string m_string_value;
    double m_threshold;
};

}  //namespace hermas

#endif /* search_condition_h */

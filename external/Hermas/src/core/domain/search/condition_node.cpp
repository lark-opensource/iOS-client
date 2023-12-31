//
//  condition_node.cpp
//  Hermas
//
//  Created by 崔晓兵 on 11/2/2022.
//

#include "condition_node.h"
#include "json.h"
#include "json_util.h"
#include "protocol_service.h"
#include <algorithm>
#include <float.h>

namespace hermas {

void ConditionNode::AddChildNode(const std::shared_ptr<ConditionNode>& child) {
    m_children.push_back(child);
}

void ConditionNode::removeChildNode(const std::shared_ptr<ConditionNode>& child) {
    auto iter = find(m_children.begin(), m_children.end(), child);
    if (iter != m_children.end()) {
        m_children.erase(iter);
    }
}

bool ConditionNode::Match(const std::string& data) {
    Json::Value json;
    bool ret = hermas::ParseFromJson(data, json);
    if (!ret) return false;
    return Match(json);
}

bool ConditionAndNode::Match(const Json::Value& json) {
    for (auto& node : m_children) {
        bool ret = node->Match(json);
        if (!ret) return false;
    }
    return true;
}

bool ConditionAndNode::Violate(const std::string& key, double threshold) {
    for (auto& node : m_children) {
        bool ret = node->Violate(key, threshold);
        if (ret) return true;
    }
    return false;
}

bool ConditionAndNode::Violate(const std::string& key, const std::pair<double, double>& region) {
    for (auto& node : m_children) {
        bool ret = node->Violate(key, region);
        if (ret) return true;
    }
    return false;
}

std::shared_ptr<ConditionNode> ConditionAndNode::Pruning(const std::string& key) {
    auto and_node = std::make_shared<ConditionAndNode>();
    for (auto& node : m_children) {
        if (node->Pruning(key) != nullptr) {
            and_node->AddChildNode(node);
        }
    }
    if (and_node->m_children.size() > 0) {
        return and_node;
    }
    return nullptr;
}


bool ConditionOrNode::Match(const Json::Value& json) {
    for (auto& node : m_children) {
        bool ret = node->Match(json);
        if (ret) return true;
    }
    return false;
}

bool ConditionOrNode::Violate(const std::string& key, double threshold) {
    for (auto& node : m_children) {
        bool ret = node->Violate(key, threshold);
        if (!ret) return false;
    }
    return true;
}

bool ConditionOrNode::Violate(const std::string& key, const std::pair<double, double>& region) {
    for (auto& node : m_children) {
        bool ret = node->Violate(key, region);
        if (!ret) return false;
    }
    return true;
}

std::shared_ptr<ConditionNode> ConditionOrNode::Pruning(const std::string& key) {
    auto or_node = std::make_shared<ConditionOrNode>();
    for (auto& node : m_children) {
        if (node->Pruning(key) != nullptr) {
            or_node->AddChildNode(node);
        }
    }
    if (or_node->m_children.size() > 0) {
        return or_node;
    }
    return nullptr;
}



ConditionLeafNode::ConditionLeafNode(ConditionJudgeType type, const std::string& key, double threshold, const std::string& string_value) : m_judge_type(type), m_key(key), m_threshold(threshold), m_string_value(string_value) {
}


bool ConditionLeafNode::Match(const Json::Value& json) {
    if (m_string_value.length() > 0 ) {
        if (m_judge_type == ConditionJudgeEqual) {
            std::string value = json[m_key].asString();
            return value == m_string_value;
        }
        return false;
    } else {
        switch (m_judge_type) {
            case ConditionJudgeLess: {
                bool ret = std::abs(json[m_key].asDouble() - m_threshold) > FLT_EPSILON;
                return (json[m_key].asDouble() < m_threshold) && ret;
                break;
            }
            case ConditionJudgeEqual:
                return std::abs(json[m_key].asDouble() - m_threshold) <= FLT_EPSILON;
                break;
                
            case ConditionJudgeGreater: {
                bool ret = std::abs(json[m_key].asDouble() - m_threshold) > FLT_EPSILON;
                return (json[m_key].asDouble() > m_threshold) && ret;
                break;
            }
            case ConditionJudgeIsNULL:
                return json[m_key].isNull();
                break;
            default:
                return false;
        }
    }
}


bool ConditionLeafNode::Violate(const std::string& key, double value) {
    if (m_key != key) return false;
    switch (m_judge_type) {
        case ConditionJudgeLess: {
            return value > m_threshold;
            break;
        }
        case ConditionJudgeEqual:
            return std::abs(value - m_threshold) > FLT_EPSILON;
            break;
            
        case ConditionJudgeGreater: {
            return value < m_threshold;
            break;
        }
        default:
            return false;
    }
}

bool ConditionLeafNode::Violate(const std::string& key, const std::pair<double, double>& region) {
    if (m_key != key) return false;
    switch (m_judge_type) {
        case ConditionJudgeLess: {
            return region.first > m_threshold;
            break;
        }
            
        case ConditionJudgeGreater: {
            return region.second < m_threshold;
            break;
        }
        default:
            return false;
    }
}

std::shared_ptr<ConditionNode> ConditionLeafNode::Pruning(const std::string& key) {
    if (m_key != key) return nullptr;
    return shared_from_this();
}


}

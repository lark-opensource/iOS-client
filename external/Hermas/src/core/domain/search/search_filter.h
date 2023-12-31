//
//  search_filter.h
//  Hermas
//
//  Created by 崔晓兵 on 16/2/2022.
//

#ifndef search_filter_hpp
#define search_filter_hpp

#include <memory>
#include "file_path.h"
#include "env.h"

namespace hermas {

class ConditionNode;

class SearchFilter {
public:
    SearchFilter(const std::shared_ptr<hermas::ConditionNode>& condition, const std::shared_ptr<Env>& env) : m_condition(condition), m_env(env) { }
    virtual ~SearchFilter() {}

    void SetNextFilter(const std::shared_ptr<SearchFilter>& next_filter);

    virtual bool Intercept(FilePath& file_path) = 0;
    
protected:
    std::shared_ptr<SearchFilter> m_next_filter;
    std::shared_ptr<ConditionNode> m_condition;
    std::shared_ptr<Env> m_env;
};


class FileNameSearchFilter : public SearchFilter {
public:
    FileNameSearchFilter(const std::shared_ptr<hermas::ConditionNode>& condition, const std::shared_ptr<Env>& env) : SearchFilter(condition, env) {}
    ~FileNameSearchFilter() {}
    virtual bool Intercept(FilePath& file_path) override;
};

class TimeSearchFilter : public SearchFilter {
public:
    TimeSearchFilter(const std::shared_ptr<hermas::ConditionNode>& condition, const std::shared_ptr<Env>& env) : SearchFilter(condition, env) {}
    ~TimeSearchFilter() {}
    virtual bool Intercept(FilePath& file_path) override;
};


}

#endif /* search_filter_hpp */

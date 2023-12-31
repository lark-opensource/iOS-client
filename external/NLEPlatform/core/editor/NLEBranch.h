//
// Created by bytedance on 2020/12/1.
//

#ifndef NLECONSOLE_NLEBRANCH_H
#define NLECONSOLE_NLEBRANCH_H

#include "nle_export.h"
#include "NLECommit.h"
#include <memory>
#include <deque>

namespace cut::model {

    class NLEBranch;

    class NLE_EXPORT_CLASS NLEBranchListener {
    public:
        NLEBranchListener() = default;
        virtual ~NLEBranchListener() = default;
        virtual void onChanged() = 0;
    };

    class NLEBranch {
    public:
        static const uint32_t MAX_COMMIT_COUNT = 50;

        /**
         * 清空所有记录
         *
         * 变更前:
         * A  B  C  D  E  F  G  H  I  J  K
         *        head ⬆ = 4 (E)
         *
         * 变更后:
         * head = 0
         *
         */
        void clear();

        /**
         * 修剪历史操作队列
         *
         * 变更前:
         * A  B  C  D  E  F  G  H  I  J  K
         *        head ⬆ = 4 (E)
         *
         * 输入:
         * redoCount = 2, undoCount = 3
         *
         * 变更后:
         * C  D  E  F  G  H
         *  head ⬆ = 2 (E)
         *
         * @param redoCount 保留最多 redo次数
         * @param undoCount 保留最多 undo 次数
         */
        void trim(int64_t redoCount, int64_t undoCount);

        /**
         * 添加一个节点
         *
         * 变更前:
         * A  B  C  D  E  F  G  H  I  J  K
         *        head ⬆ = 4 (E)
         *
         * 输入:
         * M
         *
         * 变更后:
         * M  E  F  G  H  I  J  K
         * ⬆ head = 0 (M)
         *
         * @param commit
         */
        void addCommit(const std::shared_ptr<cut::model::NLECommit>& commit);

        std::shared_ptr<cut::model::NLECommit> getHead() const; // HEAD
        std::shared_ptr<cut::model::NLECommit> getHeadPrev() const; // HEAD-1
        std::shared_ptr<cut::model::NLECommit> getHeadNext() const; // HEAD+1


        std::shared_ptr<cut::model::NLECommit> resetToNext(int32_t step = 1); // HEAD -> HEAD+1; return new HEAD
        std::shared_ptr<cut::model::NLECommit> resetToPrev(int32_t step = 1);
        std::shared_ptr<cut::model::NLECommit> goTo(const std::string &commitId);
        /**
         * trim两个commitId之间的所有done，不包含这两个commitId
         * @param startCommitId 开始提交记录
         * @param endCommitId  结束提交记录
         * @return  若数据合法且删除成功，返回true 否则返回false
         */
        bool trimRange( const std::string &startCommitId,const std::string &endCommitId );

        NLEError writeToJson(SerialContext& context) const;
        NLEError readFromJson(DeserialContext& context);

        void collectResources(std::vector<std::shared_ptr<NLEResourceNode>>& resources) const;

        void setListener(const std::shared_ptr<NLEBranchListener>& listener);
        const std::deque<std::shared_ptr<cut::model::NLECommit>> &getCommits() const;

      protected:
        NLEError onWriteToJson(SerialContext& context, nlohmann::json &jsonObject) const;
        NLEError onReadFromJson(DeserialContext& context, const nlohmann::json &jsonObject);

    private:

        std::weak_ptr<NLEBranchListener> _listener;


        //              head
        //        redo <-↓-> undo
        // front - [] [] [] [] [] [] - back
        std::deque<std::shared_ptr<cut::model::NLECommit>>::size_type head = 0;
        std::deque<std::shared_ptr<cut::model::NLECommit>> commits;
    };
}


#endif //NLECONSOLE_NLEBRANCH_H

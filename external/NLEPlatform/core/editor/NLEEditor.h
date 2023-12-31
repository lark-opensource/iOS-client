//
// Created by bytedance on 2020/5/9.
//

#ifndef NLEPLATFORM_MODEL_NLEEDITOR_H
#define NLEPLATFORM_MODEL_NLEEDITOR_H

#include "nle_export.h"
#include "NLENode.h"
#include "NLEBranch.h"
#include "NLEResourceSynchronizer.h"
#include "NLESequenceNode.h"
#include "NLEResourceNode.h"

#include <deque>
#include <vector>
#include <memory>
#include <string>
#include <map>
#include <unordered_map>
#include <mutex>
#include <ctime>
#include <sstream>

//#pragma pack(8)

namespace cut::model {

    class NLE_EXPORT_CLASS NLEEditorListener {
    public:
        NLEEditorListener() = default;

        virtual ~NLEEditorListener() = default;

        virtual void onChanged() = 0;
    };

    /**
     * NLEEditor负责维护整个工程
     *
     * NLEEditor可以理解为一个剪辑工程，目前仅支持一个NLEBranch;
     * NLEEditor记录着所有剪辑操作，支持回撤（undo）重做（redo）能力；
     * 每个剪辑操作都对应一颗完整的轨道树型结构；
     *
     * @brief The NLEEditor class
     *
     * @see https://bytedance.feishu.cn/docs/doccnH4ox8m3bgJD6fcMDrU0WWd
     */
    class NLE_EXPORT_CLASS NLEEditor {
    public:
    KEY_FUNCTION_DEC(NLEEditor);

        /**
         * 构造器
         */
        NLEEditor();

        virtual ~NLEEditor();

        /**
         * 存储接口 NLEEditor::store() 会存储 NLEBranch 的内容，
         * 不包含 workingObject 和 stageObject；
         * NLE目前不会涉及IO操作，草稿存储的输出，草稿恢复的输入，都是内存字符串；
         *
         * @param target
         * @return
         */
        NLEError store(std::shared_ptr<nlohmann::json> target) const;

        NLEError store(std::ostringstream &target) const;

        NLEError store(std::ofstream &target) const;

        NLEError store(std::string &target) const;

        std::string store() const;

        /**
         * project restore with commit history
         * @param target
         * @return
         */
        NLEError restore(const std::shared_ptr<const nlohmann::json> &source); // 实参类型为 const string& 时，将会匹配到这里，注意！
        NLEError restore(std::istringstream &source);

        NLEError restore(std::ifstream &source);

        NLEError restore(const std::string &source);

        /**
         * 暂存，同时触发NLEEditorListener回调；
         *
         * 我们可以在这个回调中触发VESDK；剪辑UI会有一些高频操作，比如持续拖动贴纸，持续调整滤镜强度等等，
         * 这些场景通过 NLEEditor::commit() 接口暂存，然后通过 NLEEditorListener 触发VESDK刷新；
         * 高频操作结束之后，再调用 NLEEditor::done() 接口记录；
         *
         * @return true表示正常执行，false表示没有执行或者出错
         *
         * @see done()
         */
        bool commit();

        /*
         * 外部重置model
         */
        void setModel(std::shared_ptr<cut::model::NLEModel> model);

        /**
         * [stage] : stage, const, immutable, read only object
         * [working] : mutable, readable & writable object
         */
        std::shared_ptr<cut::model::NLEModel> getModel() const;

        /**
         * [stage] : stage, const, immutable, read only object
         * [working] : mutable, readable & writable object
         */
        std::shared_ptr<cut::model::NLEModel> getStageModel() const;

        std::shared_ptr<cut::model::NLEBranch> getBranch() const;

        /**
         * 修剪操作历史队列;
         * 例子：除了当前记录，其他记录全部删除：trim(0, 0);
         *
         * @param redoCount 保留最多 redo次数
         * @param undoCount 保留最多 undo 次数
         */
        void trim(int64_t redoCount, int64_t undoCount);

        /**
        * 修剪操作历史队列，主要提供两个操作历史的commitId，<br>
        * 会删除这两个commitId间（不包含这两个节点）的提交记录，若提交记录不合法或者找不到提交CommitId，<br>
        * 则直接返回false<br>
        *   commit01      commit02     commit03    .....         commitN
        *     |            |               |                       |
        *    ◇ ----------  ◇ ------------- ◇  ---- ..... --------- ◇
        *
        *
        *    如上图，trimRange(commit01,commitN)后，操作历史中会将(commit01，commitN）不包含commit01和commitN中的操作历史全局裁剪掉。
        *    所以裁剪后：
        *   commit01           commitN
        *     |                   |
        *    ◇ ----------------- ◇
        * @param startCommitId  开始节点的commitID<br>
        * @param endCommit  开始结束的commitID
        */
         bool trimRange(const std::string& startCommitId, const std::string& endCommit);

        /**
         * 基于 NLEBranch head 节点，还原 workingObject，触发NLEEditorListener回调；
         * 并且清空 stageObject；
         *
         * 场景：调用了很多次 commit() 之后，通过 resetHead() 可以撤销所有 commit() 操作；
         *
         * @return true表示正常执行，false表示没有执行或者出错
         */
        bool resetHead();


        /**
         * 回滚到commitID对应的节点上, 不会做裁剪, 若是需要裁剪使用trim(undoCnt， 0)
         * <br>只是提交记录的移动</br>
         *  如图：这个是直接gotoCommitById(commit01)
         *                  ↓
         * front -  []     []         []       []       [] - back
         *      commit01 commit01  commit02  commit03
         * @return
         */
        bool  goTo(const std::string & commitId);



        /**
         * 提交变更，相当于: git commit .
         * 撤销变更，undo()
         * 重做变更，redo()
         *
         * NLEEditor::done() 记录历史（git commit），同时触发NLEBranchListener回调；我们可以在这个回调中“自动”触发文件存储，云同步等等操作；
         *
         * @param msg: 类似git commit的msg，可以用来标识当前commit的描述信息。
         * @return true表示正常执行，false表示没有执行或者出错
         */
        bool done(const std::string &msg = "");

        /**
         * 提交变更，相当于: git reset --hard HEAD^
         * @param  undoStep undo的步阶数为1
         * @return true表示正常执行，false表示没有执行或者出错
         */
        bool undo(int32_t undoStep = 1);

        /**
         * 重做变更
        * @param  redoStep redo的步阶数为1
         * @return true表示正常执行，false表示没有执行或者出错
         */
        bool redo(int32_t redoStep = 1);

        bool canUndo() const;

        bool canRedo() const;

        std::vector<std::shared_ptr<cut::model::NLEResourceNode>> getAllResources() const;

        /**
         * 监听NLEBranch变更：done() / undo() / redo() / trim()
         * @param branchListener
         */
        void setBranchListener(const std::shared_ptr<cut::model::NLEBranchListener> &branchListener);

        // 这个 listener 最后接收回调
        void setListener(const std::shared_ptr<cut::model::NLEEditorListener> &listener);

        /**
         * 设置消费端：播放器 / 草稿合成
         */
        void addConsumer(const std::shared_ptr<cut::model::NLEEditorListener> &listener);

        /**
         * 删除消费端：播放器 / 草稿合成
         */
        void removeConsumer(const std::shared_ptr<cut::model::NLEEditorListener> &listener);
        
        /**
         * 扩展草稿字段，参与草稿存盘/恢复
         */
        const std::string &getGlobalExtra(const std::string &key) const;

        /**
         * 导出
         */
        NLEError exportEditor(const std::string &exportPath) const;

        /**
         * 导入
         */
        NLEError importEditor(const std::string &exportPath);

        void setGlobalExtra(const std::string &key, const std::string &extra);

        // 设置资源同步器，TODO：后续看看
        void setSynchronizer(const std::shared_ptr<nle::resource::NLEResourceSynchronizer> &synchronizer) {}

    protected:
        /**
         * the working object ptr.
         * It may be NLEModel instance or its derived-class instance.
         * It is an empty NLEModel instance by default, and maybe reset by NLEEditor::setModel() or NLEEditor::applyCommit().
         */
        std::shared_ptr<NLEModel> workingObject;
        std::shared_ptr<NLEModel> stageObject;      // 暂存区
        std::shared_ptr<NLEBranch> editBranch;      // 持久区
        /**
         * 类注册 & feature支持 （允许子类通过重写来扩展editor能力）
         */
        virtual void modelClassesRegister();
        virtual bool featureSupport(const std::unordered_set<TNLEFeature> &features);
        /**
         * 允许定义editor中草稿模型实例的构造方法
         */
        virtual std::shared_ptr<NLEModel> createModelInstance();
        /**
         * 允许定义editor中editor实例的构造方法
         */
        virtual std::shared_ptr<NLEEditor> createEditorInstance() const;
        

    private:

        std::shared_ptr<cut::model::NLEEditorListener> _listener;
        std::vector<std::shared_ptr<cut::model::NLEEditorListener>> consumers;

        std::recursive_mutex opLock;

        std::map<std::string, std::string> globalExtraMap;

        /**
         * clear stageObject
         * reset workingObject by the input @param commit
         * @param commit
         */
        void applyCommit(NLECommit& commit);

        void notifyChanged();

    };
}


#endif //NLEPLATFORM_MODEL_NLEEDITOR_H

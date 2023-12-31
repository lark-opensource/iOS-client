//
//  NLEEditor+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/7.
//

#ifndef NLEEditor_iOS_h
#define NLEEditor_iOS_h
#import <Foundation/Foundation.h>
#import "NLEModel+iOS.h"
#import "NLEBranch+iOS.h"
#import "NLEResourceNode+iOS.h"
#import "NLEResourceSynchronizerImpl+iOS.h"
#import "NLEEditorCommitContextProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class HTSVideoData, VEEditorSession, NLEEditor_OC;
@protocol NLEEditorDelegate <NSObject>

- (void)nleEditorDidChange:(NLEEditor_OC *)editor;

@end

@interface NLEEditor_OC : NSObject

@property (nonatomic, strong) NLEModel_OC *model;

- (NLEModel_OC*)getModel;

/// 调用redo、undo、done都会回调这个delegate，确保是redo 和undo 完了之后回调。
/// 于BranchListener 不同，BranchListener 是branch变化了回调，是在redo和undo完之前回调。
/// @param delegate id<NLEEditorDelegate>
- (void)addDelegate:(id<NLEEditorDelegate>)delegate;

- (void)removeDelegate:(id<NLEEditorDelegate>)delegate;

- (void)addListener:(id<NLEEditor_iOSListenerProtocol>)listener;

- (void)removeListener:(id<NLEEditor_iOSListenerProtocol>)listener;

- (void)clearListeners;

/// 提交变更，会触发diff，生效到VE渲染
- (id<NLEEditorCommitContextProtocol>)commit;
- (void)doRender:(id<NLEEditorCommitContextProtocol>)context
      completion:(nullable void(^)(NSError *renderError))completion;

/// 这才是真正提交，只有done之后才会有undo。
/// commit可以理解为模型修改了，麻烦NLE进行diff更新效果，业务可以调多
/// 次commit，然后done是保存上一次done和这一次done之间的所有修改，因此只有调用了done之后，才可以调用undo
- (BOOL)done;

//// done的同时给这次修改标志信息，当undo/redo的时候会在回调中回传标志信息
- (BOOL)done:(NSString*)message;

//only read
- (NLEModel_OC*)getStageModel;

- (NLEBranch_OC*)getBranch;

/**
 * 修剪操作历史队列;
 * 例子：除了当前记录，其他记录全部删除：trim(0, 0);
 *
 * @param redoCount 保留最多 redo次数
 * @param undoCount 保留最多 undo 次数
 */
- (void)trim:(NSInteger)redoCount undoCount:(NSInteger)undoCount;

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
* @param endCommitId  开始结束的commitID
* @return true表示正常执行，false表示没有执行或者出错
*/
 -(BOOL)trimRange:(NSString*)startCommitId endCommit:(NSString*) endCommitId;

/**

 * 回滚到commitID对应的节点上, 不会做裁剪, 若是需要裁剪使用trim(undoCnt， 0)
 * <br>只是提交记录的移动</br>
 *  如图：这个是直接gotoCommitById(commit01)
 *                  ↓
 * front -  []     []         []       []       [] - back
 *      commit01 commit01  commit02  commit03
 * @return true表示正常执行，false表示没有执行或者出错
 */
- (BOOL)gotoCommit:(NSString*)commitId;

/// git reset HEAD^
/// 撤销上一次操作，返回YES表示undo成功
- (BOOL)undo;

/// 反撤销，返回YES表示undo成功
- (BOOL)redo;

/// 判断是否可以Undo，调用done之后才会有Undo
- (BOOL)canUndo;

/// 判断是否可以Redo，前提是调用了undo
- (BOOL)canRedo;

/**
 * 基于 NLEBranch head 节点，还原 workingObject，触发NLEEditorListener回调；
 * 并且清空 stageObject；
 *
 * 场景：调用了很多次 commit() 之后，通过 resetHead() 可以撤销所有 commit() 操作；
 *
 * @return true表示正常执行，false表示没有执行或者出错
 */
- (BOOL)resetHead;

// 设置资源同步器，TODO：后续看看
- (void)setSynchronizer:(NLEResourceSynchronizerImpl_OC*)synchronizer;

// 获取所有相关资源，TODO：后续看看
- (NSArray<NLEResourceNode_OC*>*)getResources;

/**
 * 扩展草稿字段，参与草稿存盘/恢复
 */
- (NSString*)getGlobalExtra:(NSString*)key;

- (void)setGlobalExtra:(NSString*) key extra:(NSString*)extra;

/**
 * 存储信息并返回json字符串
 */
- (NSString *)store;

/**
 * 从json字符串恢复信息
 */
- (NLEError)restore:(NSString *)jsonString;

- (NSArray<NLEResourceNode_OC*>*)getAllResources;


@end

NS_ASSUME_NONNULL_END

#endif /* NLEEditor_iOS_h */

//
//  CommentFlow.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/1.
//  


import Foundation
import RxDataSources
import Differentiator
import SKUIKit
import LarkReactionView
import SpaceInterface
import SKCommon

enum CommentAction {
    /// 更新评论数据
    case updateData(CommentData)
    /// 新增评论
    case updateNewInputData(CommentShowInputModel)
    /// MS滚动
    case scrollComment(commentId: String, replyId: String, percent: CGFloat)
    /// 新增评论失败重试
    case retryAddNewComment(commentId: String)
    /// 新增评论完成(可能成功或失败)
    case addNewCommentFinished(commentUUID: String, isSuccess: Bool, errorCode: String?)
    
    /// drive评论切换选取
    case switchComment(commentId: String)
    
    /// drive评论更新DocsInfo
    case updateDocsInfo(docsInfo: DocsInfo)
    
    case vcFollowOnRoleChange(role: FollowRole)
    
    case updateCopyTemplateURL(urlString: String)
    
    case removeAllMenu
    
    /// 取消显示激活评论，不需要通知前端
    case resetActive
    
    /// 刷新评论UI
    case reloadData
    
    enum UI {
        /// 点击了编辑
        case edit(CommentItem)
        /// 点击了回复
        case reply(CommentItem)
        ///  iPad选中评论
        case didSelect(Comment)
        
        case keyCommandUp

        case keyCommandDown
        
        case textViewDidBeginEditing(AtInputTextView)
        
        case textViewDidEndEditing(AtInputTextView)
        
        case asideKeyboardChange(options: Keyboard.KeyboardOptions, item: CommentItem)
        
        case keyboardChange(options: Keyboard.KeyboardOptions)
        
        /// 前端主动关闭
        case hideComment
        
        /// aside UI 点击非评论的空白处
        case tapBlank
        
        /// GA 之后删掉，这里是兼容一期的交互
        case inviteUserDone
        
        case cacheImage(_ image: UIImage, cacheable: CommentImageCacheable)
        
        case clickAvatar(CommentItem)

        /// 可能是链接或者人名(会检查并弹出权限请求框 )
        case clickAtInfoAndCheckPermission(atInfo: AtInfo,
                                           item: CommentItem,
                                           rect: CGRect,
                                           view: UIView)
        
        /// 直接跳转，不检查权限
        case clickAtInfoDirectly(atInfo: AtInfo)
        
        case clickURL(URL)
        
        case scanQR(String)
        
        /// 普通回复评论
        case showReaction(item: CommentItem, location: CGPoint, cell: UIView, trigerView: UIView)
        
        /// 长按评论
        case longPress(item: CommentItem, location: CGPoint, cell: UIView, trigerView: UIView)
        
        /// block reaction
        case showBlockReaction(item: CommentItem, location: CGPoint, cell: UIView, trigerView: UIView)
        
        /// aside类型的mention需要以popver方式弹出
        case mention(atInputTextView: AtInputTextView, rect: CGRect)
        
        case mentionKeywordChange(keyword: String)
        
        case insertInputImage(maxCount: Int, callback: (CommentImagePickerResult) -> Void)
        
        case showContentInvite(at: AtInfo, rect: CGRect, rectInView: UIView)
                               
        case clickTranslationIcon(CommentItem)
        
        case loadImagefailed(CommentItem)
        
        /// 点击cell上的icon
        case clickReaction(CommentItem, ReactionInfo, ReactionTapType)
        
        case clickResolve(comment: Comment, trigerView: UIView)
        
        case clickQuoteMore(comment: Comment, trigerView: UIView)
        
        /// 组件内部主动关闭
        case clickClose
        
        case hideMention
        
        case didShowAtInfo(item: CommentItem, atInfos: [AtInfo])
        
        /// 浏览评论图片
        case openImage(item: CommentItem, imageInfo: CommentImageInfo)
        
        case willDisplay(CommentItem)

        case willDisplayUnread(CommentItem)
        
        case contentBecomeInvisibale(CommentScrollInfo)
        
        case magicShareScroll(CommentScrollInfo)
        
        case clickRetry(CommentItem)
        
        case clickSendingDelete(CommentItem)
        
        case didMention(AtInfo)
        
        case switchCard(commentId: String, height: CGFloat)
        
        case panelHeightUpdate(height: CGFloat)
        
        case goPrePage(current: Comment)
        
        case goNextPage(current: Comment)
        
        case clickInputBarView
        
        case clickInputBarSendBtn(textView: AtInputTextView, attributedText: NSAttributedString, imageList: [CommentImageInfo])

        case viewWillTransition
        
        case keepPotraint(force: Bool)
        /// 准备拖动scrollView
        case willBeginDragging(items: [CommentItem])
        /// scrollView惯性滚动停止
        case didEndDecelerating
        /// scrollView手离开屏幕，没有惯性滚动
        case didEndDragging
        
        case renderEnd
    }
    
    case interaction(UI)

    /// Inter plugin communication
    enum IPC {
        typealias Callback = (Any?, Error?) -> Void
        /// 某个插件更新了评论，需要数据插件更新UI, replyId为空时
        /// 表示更新一组评论
        case refresh(commentId: String, replyId: String?)
        /// 下掉键盘并在数据源标记
        case resignKeyboard(commentId: String, replyId: String)
        /// 激活键盘并在数据源标记
        case becomeResponser
        /// 如果commentId有值，则设置该评论数据为激活评论 and 回复模式
        /// 如果commentId没有值,则设置当前激活评论数据为回复模式
        case setReplyMode(commentId: String?, becomeResponser: Bool)
        /// 当前激活评论数据的replyId为编辑模式
        case setEditMode(replyId: String, becomeResponser: Bool)
        /// 主动将当前激活评论模式设置为浏览模式
        case setNormalMode
        /// 查询评论indexPath
        case fetchIndexPath(commentId: String, replyId: String?)
        /// Aside评论获取正在回复/编辑的评论信息
        case fetchSnapshoot
        
        case fetchCommentDataDesction
        
        case resetDataCache(CommentStatsExtra?, CommentStatsExtra.Action)
        
        case activeNext
        
        case activePre
        
        case setEditDraft(CommentItem)
        
        case setReplyDraft(CommentItem, AtInfo)
        
        case setNewInputDraft(CommentShowInputModel)
        
        case clearDraft(draftKey: CommentDraftKey)
        
        case removeAllMenu
        
        // 在已有的reaction上点击人名
        case clickReactionName(userId: String, from: UIViewController?)
        
        case setMenu(MenuWeakWrapper)
        
        case setFloatCommentMode(mode: CardCommentMode)
        
        case setDriveCommentMode(mode: CardCommentMode)
        
        case fetchMenuKeys
        
        case dismisMunu(keys: [String])
        
        // float评论邀请人需要单独处理并以popver方式展示
        case showTextInvite(at: AtInfo, rect: CGRect, inView: UIView)
        
        case inviteUserDone
        
        case showResolveAndCopyMenu(comment: Comment, link: String, ability: [CommentAbility], trigerView: UIView)
        
        case prepareForAtUid(uids: Set<String>)
    }

    /// plugin之间通信，通过callback返回回调
    case ipc(IPC, IPC.Callback?)

    /* ====== 和前端有关 ======= */
    enum API {
        
        typealias Callback = (Any?, Error?) -> Void
   
        /// 回复和编辑评论
        case addComment(CommentContent, CommentWrapper)
        /// 编辑局部评论
        case editComment(CommentContent, CommentWrapper)

        /// 取消新增局部评论
        case cancelPartialNewInput
        
        /// 取消新增全文评论
        case cancelGloablNewInput
        
        /// 通知前端关掉评论卡片
        case closeComment
        
        case switchCard(commentId: String, height: CGFloat)
        
        case panelHeightUpdate(height: CGFloat)
        
        case inviteUserRequest(atInfo: AtInfo, sendLark: Bool)
        
        case requestAtUserPermission(Set<String>)
        
        case retry(CommentItem)
        
        case readMessage(CommentItem)
        
        case contentBecomeInvisibale(CommentScrollInfo)
        
        case magicShareScroll(CommentScrollInfo)
        
        case delete(CommentItem)
        
        case didMention(AtInfo)
        
        case resolveComment(commentId: String, activeCommentId: String)
        
        // reaction
        
        case addReaction(reactionKey: String, item: CommentItem)
        case removeReaction(reactionKey: String, item: CommentItem)
        
        case addContentReaction(reactionKey: String, item: CommentItem)
        case removeContentReaction(reactionKey: String, item: CommentItem)
        
        case setDetailPanel(reaction: CommentReaction, show: Bool)
        case getReactionDetail(CommentItem, CommentReaction)
        case getContentReactionDetail(CommentItem)
        
        case translate(CommentItem)
        /// 打开评论图片。index：图片下标。 -1表示关闭
        case activateImageChange(item: CommentItem, index: Int)
        
        case anchorLinkSwitch(commentId: String)
        
        case copyAnchorLink(Comment)
        case shareAnchorLink(Comment)
    }

    case api(API, API.Callback?)
    
    enum Tea {
        case cancelTranslateClick(CommentItem)
        case showOriginalClick(CommentItem)
        case cancelClick
        case addComment(Comment, isFirst: Bool)
        case reactionComment(CommentItem, isNew: Bool, key: String)
        case finishClick(commentId: String, isSame: Bool)
        case editConfirm(CommentItem)
        case deleteClick(CommentItem)
        case beginEdit
        case translateClick(CommentItem)
        case reactionCommentPanel(CommentItem)
        case copyAnchorLink(Comment)
        case shareAnchorLink(Comment)
        case fpsPerformance(params: [CommentTracker.PerformanceKey: Any])
        case renderPerformance(params: [CommentTracker.PerformanceKey: Any])
        case editPerformance(params: [CommentTracker.PerformanceKey: Any])
        // 评论成功率上报 ↓
        case reportCreateCommentSend(uuid: String)
        case reportReplyCommentSend(uuid: String)
        case reportEditCommentSend(uuid: String)
        // 评论成功率上报 ↑
    }
    
    case tea(Tea)
}
                            
enum CommentState {
    
    /// iPad 展示/隐藏loading
    case loading(Bool)

    enum HUD {
       case success(String)
       case failure(String)
       case tips(String)
    }
    /// 在文档上层展示toast
    case toast(HUD)
    
    /// 更新Drive和Aside评论数字描述文字
    case updateTitle(String)

    /// 刷新列表
    case reload

    /// 局部刷新评论UI
    case updateItems([IndexPath])
    
    /// 局部刷新评论UI
    case updateSections([Int])
    
    /// diff 结果,  要和batchUpdatesCompletion成对匹配！
    case diffResult([CommentSection], [IndexPath]?)
    
    /// 同步修改后的数据（多页数据，如aside评论）
    case syncData([CommentSection])
    
    /// 同步修改后的数据（多页数据，如aside评论）
    case syncPageData(data: [CommentSection], currentPage: Int)

    /// 每轮diff结束后 tableView动画完成的通知
    case batchUpdatesCompletion
    
    /// 计算当前「参考评论」位置。为了在协同数据返回时当前浏览的评论
    /// 不被挤上去/挤下来，引入参考评论这个概念，当刷新评论后，要保持参考
    /// 评论offset位置不变。需要结合keepStill action使用
    case locateReference
    
    /// 调整「参考评论」到刷新前的位置，需要结合locateReference使用
    case keepStill
    
    /// 侧边栏评论需要对齐
    case align(indexPath: IndexPath, position: CGFloat?)
    
    /// 浮窗评论 需要高亮到某个位置
    case foucus(indexPath: IndexPath, position: UITableView.ScrollPosition, highlight: Bool)
    
    /// 滚动到某个位置
    case keepInputVisiable(indexPath: IndexPath, force: Bool)
    
    /// 确保IndexPath的评论在视口范围
    case ensureInScreen(IndexPath)

    /// 设置table底部inset, duration是键盘动画时间
    case scrollAboveKeyboard(toIndexPath: IndexPath, keyboardFrame: CGRect, bottomInset: CGFloat, duration: Double)
    
    case updateDocsInfo(DocsInfo)
    
    case updatePermission(CommentPermission)
    // iPad 监听键盘快捷方式
    case listenKeyboard
    
    ///  在输入框上展示权限pop提示(旧架构在UI曾处理。新架构在menu plugin处理)
    case showTextInvite(at: AtInfo, rect: CGRect, inView: UIView)
    /// 强制Aside输入框激活
    case forceInputActiveIfNeed(at: IndexPath)
    
    case refreshAtUserText(at: IndexPath)
    
    /// 通知Float评论翻页
    case prePaging(Int)
    /// 通知Float评论翻页
    case nextPaging(Int)
    
    /// 更新输入框和输入条隐藏/显示状态，show为true是draftKey不为空
    case refreshFloatBarView(show: Bool, draftKey: CommentDraftKey?)
    
    /// 激活/取消激活输入框，并设置草稿, draftKey为空时清空输入框草稿缓存
    case updateFloatTextView(active: Bool, draftKey: CommentDraftKey?)
    
    /// 同步模式到UI
    case updaCardCommentMode(CardCommentMode)
    
    /// 滚动到某条评论相对锚点底部百分比位置
    case scrollToItem(indexPath: IndexPath, percent: CGFloat)
    /// 内部主动关闭UI
    case dismiss
    
    case openDocs(url: URL)
    case showUserProfile(userId: String, from: UIViewController?)
    case scanQR(code: String)
    
    case setCopyAnchorLinkEnable(Bool)
    
    case setTranslateConfig(CommentBusinessConfig.TranslateConfig?)
}

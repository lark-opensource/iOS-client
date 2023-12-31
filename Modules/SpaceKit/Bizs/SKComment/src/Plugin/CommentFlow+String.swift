//
//  CommentFlow+Ext.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/19.
//  


import Foundation

/// 用于日志信息
extension CommentState: CustomStringConvertible {
    
    var description: String {
        switch self {
        case let .loading(res):
            return "loading: \(res)"
        case .toast:
            return "toast"
        case .reload:
            return "reload"
        case .updateItems:
            return "updateItems"
        case let .updateSections(sections):
            return "updateSections: \(sections)"
        case .diffResult:
            return "diffResult"
        case .syncData:
            return "syncData"
        case .batchUpdatesCompletion:
            return "batchUpdatesCompletion"
        case .locateReference:
            return "locateReference"
        case .keepStill:
            return "keepStill"
        case let .align(indexPath, position):
            return "align indexPath:\(indexPath) pos:\(position ?? -1)"
        case let .foucus(indexPath, _, hilight):
            return "foucus:\(indexPath) hilight:\(hilight)"
        case .ensureInScreen:
            return  "ensureInScreen"
        case let .scrollAboveKeyboard(to, frame, inset, duration):
            return "scrollAboveKeyboard to:\(to) keyboardFrame:\(frame) bottomInset:\(inset) duration:\(duration)"
        case .updateDocsInfo:
            return "updateDocsInfo"
        case .updatePermission:
            return "updatePermission"
        case .listenKeyboard:
            return "listenKeyboard"
        case .showTextInvite:
            return "showTextInvite"
        case let .keepInputVisiable(index, force):
            return "keepInputVisiable index:\(index) force:\(force)"
        case let .forceInputActiveIfNeed(at):
            return "forceInputActiveIfNeed at:\(at)"
        case let .refreshAtUserText(at):
            return "refreshAtUserText at:\(at)"
        case let .updateTitle(str):
            return "updateTitle: \(str)"
        case let .syncPageData(data, page):
            return "syncPageData count:\(data.count) page:\(page)"
        case let .refreshFloatBarView(show, draft):
            return "refreshFloatBarView: \(show)"
        case let .updateFloatTextView(active, draft):
            return "updateFloatTextView: \(active)"
        case let .updaCardCommentMode(mode):
            return "updaCardCommentMode \(mode)"
        case let .prePaging(page):
            return "prePaging \(page)"
        case let .nextPaging(page):
            return "nextPaging \(page)"
        case let .scrollToItem(indexPath, percent):
            return "scrollToItem \(indexPath) \(percent)"
        case .dismiss:
            return "dismiss"
        case .openDocs:
            return "openDocs"
        case .showUserProfile:
            return "showUserProfile"
        case .scanQR:
            return "scanQR"
        case .setCopyAnchorLinkEnable:
            return "setCopyAnchorLinkEnable"
        case let .setTranslateConfig(config):
            return "setTranslateConfig: \(config?.enableCommentTranslate ?? false)"
        }
    }
}

extension CommentAction: CustomStringConvertible {
    
    var description: String {
        switch self {
        case let .updateData(commentData):
            return "updateData count:\(commentData.comments.count) page:\(commentData.currentPage) id:\(commentData.currentCommentID) "
        case let .updateNewInputData(model):
            return "updateNewInputData isWhole:\(model.isWhole) type:\(model.type)"
        case let .retryAddNewComment(commentId):
            return "retryAddNewComment \(commentId)"
        case let .addNewCommentFinished(commentUUID):
            return "addNewCommentFinished \(commentUUID)"
        case .switchComment:
            return "switchComment"
        case .updateDocsInfo:
            return "updateDocsInfo"
        case let .vcFollowOnRoleChange(role):
            return "vcFollowOnRoleChange role:\(role)"
        case .removeAllMenu:
            return "removeAllMenu"
        case .updateCopyTemplateURL:
            return "updateCopyTemplateURL"
        case .resetActive:
            return "resetActive"
        case let .interaction(ui):
            switch ui {
            case let .edit(item):
                return "edit cId:\(item.commentId) rId:\(item.replyID)"
            case let .reply(item):
                return "reply cId:\(item.commentId) rId:\(item.replyID)"
            case let .didSelect(comment):
                return "didSelect cId:\(comment.commentID)"
            case .keyCommandUp:
                return "keyCommandUp"
            case .keyCommandDown:
                return "keyCommandDown"
            case .textViewDidBeginEditing:
                return "textViewDidBeginEditing"
            case .textViewDidEndEditing:
                return "textViewDidEndEditing"
            case let .asideKeyboardChange(options, _):
                return "keyboardChange event:\(options.event)"
            case let .keyboardChange(options):
                return "keyboardChange event:\(options.event)"
            case .hideComment:
                return "hideComment"
            case .tapBlank:
                return "tapBlank"
            case .inviteUserDone:
                return "inviteUserDone"
            case .cacheImage:
                return ""
            case .clickAvatar:
                return "clickAvatar"
            case .clickAtInfoAndCheckPermission:
                return "clickAtInfoAndCheckPermission"
            case .clickURL:
                return "clickURL"
            case .clickAtInfoDirectly:
                return "clickAtInfoDirectly"
            case let .showReaction(item, location, _, _):
                return "showReaction replyID:\(item.replyID) location:\(location)"
            case let .showBlockReaction(item, location, _, _):
                return "showBlockReaction replyID:\(item.replyID) location:\(location)"
            case let .longPress(item, location, _, _):
                return "longPress replyID:\(item.replyID) location:\(location)"
            case .mention:
                return "mention"
            case .mentionKeywordChange:
                return "mention"
            case .insertInputImage:
                return "handelInsertInputImage"
            case .showContentInvite:
                return "showContentInvite"
            case .clickTranslationIcon:
                return "clickTranslationIcon"
            case .loadImagefailed:
                return "loadImagefailed"
            case let .clickReaction(_, info, type):
                return "clickReaction key:\(info.reactionKey) type:\(type)"
            case let .clickResolve(comment, _):
                return "clickResolve: \(comment.commentID)"
            case .clickClose:
                return "clickClose"
            case .hideMention:
                return "hideMention"
            case .didShowAtInfo:
                return "didShowAtInfo"
            case .openImage:
                return "openImage"
            case .willDisplayUnread:
                return "willDisplayUnread"
            case .contentBecomeInvisibale:
                return "contentBecomeInvisibale"
            case .magicShareScroll:
                return "magicShareScroll"
            case .clickRetry:
                return "clickRetry"
            case .clickSendingDelete:
                return "clickSendingDelete"
            case .didMention:
                return "didMention"
            case let .switchCard(commentId: commentId, height: height):
                return "didMention commentId:\(commentId) height:\(height)"
            case .goPrePage:
                return "goPrePage"
            case .goNextPage:
                return "goNextPage"
            case .clickInputBarView:
                return "clickInputBarView"
            case .clickInputBarSendBtn:
                return "clickInputBarSendBtn"
            case .viewWillTransition:
                return "viewWillTransition"
            case let .panelHeightUpdate(height):
                return "panelHeightUpdate: \(height)"
            case .scanQR:
                return "scanQR"
            case .clickQuoteMore:
                return "clickQuoteMore"
            case let .keepPotraint(force):
                return "keepPotraint: \(force)"
            case .willBeginDragging:
                return "willBeginDragging"
            case .didEndDragging:
                return "didEndDragging"
            case .didEndDecelerating:
                return "didEndDecelerating"
            case .willDisplay:
                return ""
            case .renderEnd:
                return "renderEnd"
            }
    
        case let .ipc(action, _):
            switch action {
            case let .refresh(commentId, replyId):
                return "refresh cId:\(commentId) rId:\(replyId)"
            case let .resignKeyboard(commentId, replyId):
                return "resignKeyboard cId:\(commentId) rd:\(replyId)"
            case .becomeResponser:
                return "becomeResponser"
            case let .setReplyMode(commentId, becomeResponser):
                return "setReplyMode cId:\(commentId) first:\(becomeResponser)"
            case let .setEditMode(replyId, becomeResponser):
                return "setEditMode rId:\(replyId) first:\(becomeResponser)"
            case .setNormalMode:
                return "setNormalMode"
            case let .fetchIndexPath(commentId, replyId):
                return "fetchIndexPath cId:\(commentId) rId:\(replyId)"
            case .fetchSnapshoot:
                return "fetchSnapshoot"
            case .activeNext:
                return "activeNext"
            case .activePre:
                return "activePre"
            case .setEditDraft:
                return "setEditDraft"
            case .setReplyDraft:
                return "setReplyDraft"
            case let .clearDraft(key):
                return "clearDraft: \(key.customKey)"
            case .setNewInputDraft:
                return "setNewInputDraft"
            case .removeAllMenu:
                return "removeAllMenu"
            case .clickReactionName:
                return "removeAllMenu"
            case .setMenu:
                return "setMenu"
            case let .setFloatCommentMode(mode):
                return "setFloatCommentMode \(mode)"
            case let .setDriveCommentMode(mode):
                return "setDriveCommentMode \(mode)"
            case .fetchMenuKeys:
                return "fetchMenuKeys"
            case .dismisMunu(keys: let keys):
                return "dismisMunu: \(keys)"
            case .showTextInvite:
                return "showTextInvite"
            case .inviteUserDone:
                return "inviteUserDone"
            case .showResolveAndCopyMenu:
                return "showResolveAndCopyMenu"
            case let .prepareForAtUid(ids):
                return "prepareForAtUid count:\(ids.count)"
            case .fetchCommentDataDesction, .resetDataCache:
                return ""
            }

        case let .api(action, _):
            switch action {
            case let .addComment(_, commentWrapper):
                return "addComment replyId:\(commentWrapper.commentItem.replyID)"
            case let .editComment(_, commentWrapper):
                return "editComment replyId:\(commentWrapper.commentItem.replyID)"
            case let .switchCard(commentId, position):
                return "switchCard commentId:\(commentId) position:\(position)"
            case .inviteUserRequest:
                return "inviteUserRequest"
            case .requestAtUserPermission:
                return "requestAtUserPermission"
            case .closeComment:
                return "closeComment"
            case let .retry(item):
                return "retry replyID:\(item.replyID)"
            case .readMessage(_):
                return "readMessage"
            case let .contentBecomeInvisibale(info):
                return "contentBecomeInvisibale cId:\(info.commentId) rId:\(info.replyId) p:\(info.replyId)"
            case let .magicShareScroll((info)):
                return "magicShareScroll cId:\(info.commentId) rId:\(info.replyId) p:\(info.replyPercentage)"
            case let .delete(item):
                return "delete replyId:\(item.replyID)"
            case .didMention(_):
                return "didMention"
            case let .resolveComment(commentId, activeCommentId):
                return "resolveComment commentId:\(commentId) activeCommentId:\(activeCommentId)"
            case let .addReaction(reactionKey, item):
                return "addReaction replyId:\(item.replyID) reactionKey:\(reactionKey)"
            case let .removeReaction(reactionKey, item):
                return "removeReaction replyId:\(item.replyID) reactionKey:\(reactionKey)"
            case let .addContentReaction(reactionKey, item):
                return "addContentReaction commentId:\(item.commentId) reactionKey:\(reactionKey)"
            case let .removeContentReaction(reactionKey, item):
                return "removeContentReaction commentId:\(item.commentId) reactionKey:\(reactionKey)"
            case .getReactionDetail:
                return "getReactionDetail"
            case .getContentReactionDetail:
                return "getContentReactionDetail"
            case .translate:
                return "translate"
            case let .activateImageChange(item, index):
                return "activateImageChange replyId:\(item.replyID) index:\(index)"
            case .cancelPartialNewInput:
                return "cancelPartialNewInput"
            case .cancelGloablNewInput:
                return "cancelGloablNewInput"
            case let .panelHeightUpdate(height):
                return "panelHeightUpdate: \(height)"
            case .setDetailPanel:
                return "setDetailPanel"
            case let .anchorLinkSwitch(commentId):
                return "anchorLinkSwitch commentId:\(commentId)"
            case let .copyAnchorLink(comment):
                return "copyAnchorLink:\(comment.commentID)"
            case let .shareAnchorLink(comment):
                return "setDetailPanel:\(comment.commentID)"
            }
        case let .scrollComment(commentId, replyId, percent):
            return "scrollComment cId:\(commentId) rId:\(replyId) p:\(percent)"
        case .tea:
            return ""
        case .reloadData:
            return "reloadData"
        }
    }
}

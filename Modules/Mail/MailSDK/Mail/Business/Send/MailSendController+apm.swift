//
//  MailSendController+apm.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/13.
//

import Foundation
import WebKit

extension MailSendController {
    func apmMarkSendStart() {
        let event = MailAPMEvent.SendDraft()
        event.markPostStart()
        apmHolder[MailAPMEvent.SendDraft.self] = event
    }

    func apmSuspendSendTimer() {
        apmHolder[MailAPMEvent.SendDraft.self]?.suspend()
    }

    func apmResumeSendTimer() {
        apmHolder[MailAPMEvent.SendDraft.self]?.resume()
    }

    func apmEndSend(status: MailAPMEventConstant.CommonParam) {
        apmHolder[MailAPMEvent.SendDraft.self]?.endParams.append(status)
        apmHolder[MailAPMEvent.SendDraft.self]?.postEnd()
    }

    func apmEndSendCustom(status: MailAPMEvent.SendDraft.EndParam) {
        apmHolder[MailAPMEvent.SendDraft.self]?.endParams.append(status)
        apmHolder[MailAPMEvent.SendDraft.self]?.postEnd()
    }
}

extension MailSendController {
    typealias loadSence = MailAPMEvent.DraftLoaded.CommonParam
    func actionToLoadSence() -> loadSence? {
        var sence: loadSence?  = nil
        if self.action == .reply || self.action == .sendToChat_Reply {
            sence = MailAPMEvent.DraftLoaded.CommonParam.sence_reply
        } else if self.action == .replyAll {
            sence = MailAPMEvent.DraftLoaded.CommonParam.sence_reply_all
        } else if self.action == .forward || self.action == .sendToChat_Forward {
            sence = MailAPMEvent.DraftLoaded.CommonParam.sence_forward
        } else if self.action == .reEdit {
            sence = MailAPMEvent.DraftLoaded.CommonParam.sence_edit_again
        } else if self.action == .fromAddress {
            sence = MailAPMEvent.DraftLoaded.CommonParam.sence_mail_to
        } else if self.action == .draft || self.action == .messagedraft {
            sence = MailAPMEvent.DraftLoaded.CommonParam.sence_draft
        } else if self.action == .new {
            sence = MailAPMEvent.DraftLoaded.CommonParam.sence_normal
        }
        return sence
    }
    func strLoadSence() -> String {
        if let sence = actionToLoadSence() {
            return sence.value as? String ?? ""
        }
        return ""
    }
    func apmSendLoadStart() {
        if self.action == .outOfOffice {
            return
        }
        let event = MailAPMEvent.DraftLoaded()
        if let sence: loadSence = actionToLoadSence() {
            event.commonParams.append(sence)
        }
        event.markPostStart()
        apmHolder[MailAPMEvent.DraftLoaded.self] = event
    }

    func apmSendLoadEnd(status: MailAPMEventConstant.CommonParam,
                        renderParam: [String: Any]? = nil) {
        if self.action == .outOfOffice {
            return
        }
        var count = 0
        var draftId = ""
        if let draft = draft {
            count = draft.content.bodyHtml.count
            draftId = draft.id
        }
        let bodyLengthParam = MailAPMEvent.DraftLoaded.EndParam.mail_body_length(count)
        let idParam = MailAPMEvent.DraftLoaded.EndParam.draft_id(draftId)
        apmHolder[MailAPMEvent.DraftLoaded.self]?.endParams.append(bodyLengthParam)
        apmHolder[MailAPMEvent.DraftLoaded.self]?.endParams.append(idParam)
        let hitPreRender = self.scrollContainer.webView.renderJSCallBackSuccess

        let hitParam = MailAPMEvent.DraftLoaded.EndParam.hit_edit_pre_render(hitPreRender)
        let hitCache = MailAPMEvent.DraftLoaded.EndParam.hit_edit_cache(self.scrollContainer.webView.useCached)
        apmHolder[MailAPMEvent.DraftLoaded.self]?.endParams.append(hitParam)
        apmHolder[MailAPMEvent.DraftLoaded.self]?.endParams.append(status)
        apmHolder[MailAPMEvent.DraftLoaded.self]?.endParams.append(hitCache)
        if let param = renderParam, !param.isEmpty, let content = param["eventStatistic"] as? [String : Any] {
            if var config = apmHolder[MailAPMEvent.DraftLoaded.self]?.reciableConfig {
                if var detailDic = content["latencyDetails"] as? [String : Any] {
                    let callTime = self.scrollContainer.webView.renderCallTime
                    let respTime = self.scrollContainer.webView.renderReceiveTime
                    if let callEndTime = content["commandReceiveTime"] as? Int, callTime > 0, callEndTime - callTime >= 0 {
                        detailDic["bridge_command_cost_time"] = callEndTime - callTime
                    }
                    if let respStartTime = content["commandReturnTime"] as? Int, respTime > 0, respTime - respStartTime >= 0 {
                        detailDic["bridge_return_cost_time"] = respTime - respStartTime
                    }
                    for (key, value) in detailDic {
                        apmHolder[MailAPMEvent.DraftLoaded.self]?
                            .appendCustomLantency(param: MailAPMEventConstant.CommonParam.customKeyValue(key: key,
                                                                                                         value: value))
                    }
                }
                if let extraCategory = content["extraCategories"] as? [String : Any] {
                    for (key, value) in extraCategory {
                        apmHolder[MailAPMEvent.DraftLoaded.self]?
                            .endParams.append(MailAPMEventConstant.CommonParam.customKeyValue(key: key,
                                                                                              value: value))
                    }
                }
            }

        }
        apmHolder[MailAPMEvent.DraftLoaded.self]?.postEnd()
    }
    func apmSuspendLoad() {
        apmHolder[MailAPMEvent.DraftLoaded.self]?.suspend()
    }
}

extension MailSendController {

    func apmSaveDraftStart(param: DraftSaveCommonParam) {
        if self.action == .outOfOffice {
            return
        }
        let event = MailAPMEvent.SaveDraft()
        event.commonParams.append(param)
        event.markPostStart()
        apmHolder[MailAPMEvent.SaveDraft.self] = event
    }

    func apmSaveDraftEnd(status: MailAPMEventConstant.CommonParam, error: Error? = nil) {
        if self.action == .outOfOffice {
            return
        }
        apmHolder[MailAPMEvent.SaveDraft.self]?.endParams.append(status)
        apmHolder[MailAPMEvent.SaveDraft.self]?.endParams.appendError(error: error)

        if let content = self.saveDraftParam {
                if var detailDic = content["latencyDetails"] as? [String : Any] {
                    let callTime = self.scrollContainer.webView.saveCallTime
                    let respTime = self.scrollContainer.webView.saveReceiveTime
                    if let callEndTime = content["commandReceiveTime"] as? Int, callTime > 0, callEndTime - callTime >= 0 {
                        detailDic["bridge_command_cost_time"] = callEndTime - callTime
                    }
                    if let respStartTime = content["commandReturnTime"] as? Int, respTime > 0, respTime - respStartTime >= 0 {
                        detailDic["bridge_return_cost_time"] = respTime - respStartTime
                    }
                    for (key, value) in detailDic {
                        apmHolder[MailAPMEvent.SaveDraft.self]?
                            .appendCustomLantency(param: MailAPMEventConstant.CommonParam.customKeyValue(key: key,
                                                                                                         value: value))
                    }
                }
        }

        apmHolder[MailAPMEvent.SaveDraft.self]?.postEnd()
    }
}

extension MailSendController {
    // 白屏检测
    func checkBlank() {
        // (falseReport, isBlank)
        func judgeAccuracy(renderSuccess: Bool,
                           hasContent: Bool?,
                           isBlank: Int,
                           sendAction: MailSendAction,
                           hasSig: Bool,
                           domReady: Int,
                           width: Int,
                           height: Int,
                           blankRate: Int,
                           clearRate: Int) -> (Int, Int) {
            var falseReport = 0
            var blankRes = isBlank
            // 未渲染成功
            if !renderSuccess {
                if isBlank == 0 {
                    falseReport = 1 // 未渲染成功，判断为非白屏，判断为误报
                }
            } else if let hasText = hasContent {
                if !hasText && !hasSig {
                    if isBlank == 1 {   //渲染成功，没有内容，判断为白屏，判断为准确，并对白屏结果做修正
                        blankRes = 0    // 做一个修正
                        MailLogger.info("[blank_check] set isBlank to 0")
                    } else if isBlank == 0 &&
                                (sendAction == .forward ||
                                 sendAction == .reply ||
                                 sendAction == .replyAll ||
                                 sendAction == .draft) { //渲染成功，没有内容，判断为非白屏，判断为误报
                        falseReport = 1 // 漏判了
                    }
                } else {
                    if isBlank == 1 { // 渲染成功，有内容，判断为白屏，判断为误报
                        falseReport = 1
                    }
                }
            }
            // 对异常数据添加风神上报，方便拉日志oncall
            if blankRes == 1 || falseReport == 1 {
                let event = MailAPMEventSingle.BlankCheck()
                event.endParams.append(MailAPMEventSingle.BlankCheck.EndParam.page_key("compose"))
                event.endParams.append(MailAPMEventSingle.BlankCheck.EndParam.is_blank(blankRes))
                event.endParams.append(MailAPMEventSingle.BlankCheck.EndParam.dom_ready(domReady))
                event.endParams.append(MailAPMEventSingle.BlankCheck.EndParam.false_report(falseReport))
                event.endParams.append(MailAPMEventConstant.CommonParam.status_exception)
                event.markPostStart()
                event.postEnd()
                // 打印必要的信息方便后续定位问题
                MailLogger.info("[blank_check] raw info, renderSuccess=\(renderSuccess), hasContent=\(hasContent), isBlank=\(isBlank), sendAction=\(sendAction), hasSig=\(hasSig), domReady=\(domReady), falseReport=\(falseReport), width=\(width), height=\(height), blankRate=\(blankRate), clearRate=\(clearRate)")
            }
            return (falseReport, blankRes)
        }
        guard accountContext.featureManager.open(.mailCheckBlank) else { return }
        // ooo不检测
        if self.action == .outOfOffice {
            return
        }
        let stayTime = Int(Date().timeIntervalSince(self.initDate ?? Date()) * 1000)
        var param = BlankCheckParam(backgroundColors: [UIColor.ud.bgBody])
        let isReady = self.scrollContainer.webView.isReady
        let actionStr = self.strLoadSence()
        let theadId = self.draft?.threadID ?? ""
        let start = MailTracker.getCurrentTime()
        let renderSuccess = self.renderSuccess
        let hasContent = self.hasContent
        let action = self.action
        var hasSig = false
        if let sig = self.scrollContainer.webView.sigId, !sig.isEmpty, sig != "0" {
            hasSig = true
        }
        guard let window = self.view.window else { return }
        guard self.scrollContainer.webView.bounds.size.width > 0 else { return }
        let scrollHeight: CGFloat = self.scrollContainer.contentOffset.y
        let webviewOffsetY: CGFloat = self.scrollContainer.webView.frame.origin.y
        var startY: CGFloat = 0
        var snapHeight: CGFloat = self.scrollContainer.webView.contentHeight
        // 说明webview开头的位置已经移动到了上面看不见了
        if scrollHeight > webviewOffsetY {
            startY = scrollHeight - webviewOffsetY
        }
        // 最大截屏幕可视区域数据来判断即可
        if snapHeight > UIScreen.main.bounds.size.height {
            snapHeight = UIScreen.main.bounds.size.height
        }
        let config = WKSnapshotConfiguration()
        config.rect = CGRect(x: 0,
                             y: startY,
                             width: self.scrollContainer.webView.bounds.size.width,
                             height: snapHeight)
        param.snapConfig = config
        let trueWidth = Int(self.scrollContainer.webView.bounds.size.width)
        let trueHeight = Int(self.scrollContainer.webView.contentHeight)
        self.scrollContainer.webView.mailCheckBlank(param: param, completionHandler: { res in
            switch res {
            case .failure(let err) :
                guard let err:BlankCheckError  = err as? BlankCheckError else {
                    return
                }
                let domReady = isReady ? 1 : 0
                let is_blank = (err == BlankCheckError.ImageSizeInvaild) ? 1 : 0
                let (falseReport, isBlank) = judgeAccuracy(renderSuccess: renderSuccess,
                                                                hasContent: hasContent,
                                                                isBlank: is_blank,
                                                                sendAction: action,
                                                                hasSig: hasSig,
                                                                domReady: domReady,
                                                                width: 0,
                                                                height: 0,
                                                           blankRate: 0,
                                                           clearRate: 0)
                MailTracker.log(event: "email_blank_check_dev",
                                params: ["page_key": "compose",
                                         "error_des": err.description,
                                         "thread_id": theadId,
                                         "is_blank": isBlank,
                                         "send_action": actionStr,
                                         "stay_time": stayTime,
                                         "dom_ready": domReady,
                                         "false_report": falseReport])
            case .success(let res):
                let domReady = isReady ? 1 : 0
                let (falseReport, isBlank) = judgeAccuracy(renderSuccess: renderSuccess,
                                                                hasContent: hasContent,
                                                                isBlank: res.is_blank,
                                                                sendAction: action,
                                                                hasSig: hasSig,
                                                                domReady: domReady,
                                                                width: trueWidth,
                                                           height: trueHeight,
                                                           blankRate: res.blank_rate,
                                                           clearRate: res.clear_rate)
                MailTracker.log(event: "email_blank_check_dev",
                                params: ["page_key": "compose",
                                         "error_des": "",
                                         "cut_screen_time": res.cut_screen_time,
                                         "total_time": res.total_time,
                                         "thread_id": theadId,
                                         "stay_time": stayTime,
                                         "is_blank": isBlank,
                                         "blank_rate": res.blank_rate,
                                         "clear_rate": res.clear_rate,
                                         "send_action": actionStr,
                                         "dom_ready": domReady,
                                         "false_report": falseReport])

            }
        })
    }
}



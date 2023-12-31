//
//  MailDraftSaveState.swift
//  MailSDK
//
//  Created by majx on 2019/11/13.
//

import Foundation

class MailDraftSaveEnableChecker {
    var initDraft: MailDraft?
    weak var sendVC: MailSendController?
    var currentDraft: MailDraft? {
        return sendVC?.draft
    }
    var discardDraft: Bool = false
    /// after webview ready 1s, start accept content change event
    var htmlContentDidChange = false
    /// change count since last saving draft
    var htmlContentChangeCount = 0
    let autoSaveDraftThreshold = 10
    /// click save button actively
    var saveDraftBtnClick = false

    func shouldSaveDraft() -> Bool {
        if discardDraft {
            return false
        }
        /// must have init draft and currentDraft
        if initDraft == nil || currentDraft == nil {
            return false
        }
        /// save draft button click
        if saveDraftBtnClick {
            saveDraftBtnClick = false
            return true
        }
        /// draft save checker rules
        if let currentDraft = currentDraft {
            if htmlContentDidChange
                || initDraft != currentDraft {
                return true
            }
        }
        return false
    }
}

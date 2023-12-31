//
//  MinutesClipViewController+Subtitle.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/6.
//
import MinutesFoundation
import UniverseDesignToast

extension MinutesClipViewController: MinutesSubtitlesViewDelegate {
    func didFinishedEdit() {
    }

    func didBeginSearchKeywords() {
    }

    func doKeyWordSearch(text: String) {
    }

    func translatePullRefreshSuccess() {
        checkMinutesReady()
    }

    func doAddComments() {
    }
    
    func showComments() {
    }

    func showNoticeViewForSubtitlesVC() {
    }
    
    func hideNoticeViewForSubtitlesVC() {
    }
    
    func enterSpeakerEdit(finish: @escaping() -> Void) {
    }

    func finishSpeakerEdit() {
    }

    func showOriginalTextViewBy(subtitle: UIViewController, attributedString: NSAttributedString) {
        showOriginalTextView(attributedString)
    }

    func showToast(text: String) {
        UDToast.showTips(with: text, on: self.view)
    }
    
    func showRefreshViewBy(subtitle: UIViewController) {
    }

    func hideHeaderBy(subtitle: UIViewController) {
    }

    func didTappedText(_ startTime: String) {
        
    }
}

extension MinutesClipViewController: MinutesSubtitlesViewDataProvider {
    func switchToDetailTab() {}

    func subtitlesViewVisbleHeight() -> CGFloat {
        return pagingView.bounds.height - titleViewVisbleHeight()
    }

    func currentTranslateLanguage() -> String {
        return ""
    }
    
    func titleViewVisbleHeight() -> CGFloat {
        return titleViewHeight - pagingView.mainScrollView.contentOffset.y
    }

    func videoControlViewHeight() -> CGFloat {
        return videoControlView.frame.height
    }

    func translationChosenLanguage() -> String {
        return self.curTranslateChosenLanguage.name
    }
    func isDetailInLandscape() -> Bool {
        return self.isInLandScape
    }
    func isDetailInVideo() -> Bool {
        return self.isVideo
    }
    func isDetailInTranslationMode() -> Bool {
        return self.isInTranslationMode
    }
    func isDetailInSearching() -> Bool {
        return false
    }
}

//
//  MinutesDetailViewController+Summary.swift
//  Minutes
//
//  Created by panzaofeng on 2022/1/20.
//
import MinutesFoundation
import UniverseDesignToast

extension MinutesDetailViewController: MinutesSubtitlesViewDelegate {

    func didBeginSearchKeywords() {
        if isSearching { return }
        showSearchBar()
        subtitlesViewController?.enterSearch()
        infoViewController?.enterSearch()
        summaryViewController?.enterSearch()
    }

    func doKeyWordSearch(text: String) {
        self.showSearchBarWithKeyWord(text: text)
    }
    
    func translatePullRefreshSuccess() {
        checkMinutesReady(isFirstRequest: false)
    }
    func doAddComments() {
    }
    func showComments() {
    }

    func showNoticeViewForSubtitlesVC() {
        showNoticeButton()
    }
    func hideNoticeViewForSubtitlesVC() {
        hideNoticeButton()
    }
    func enterSpeakerEdit(finish: @escaping() -> Void) {
        preEnterSpeakerEdit(type: .quick, finish: finish)
    }

    func finishSpeakerEdit() {
        viewModel.editSession = nil
        subtitlesViewController?.editSession = nil
    }

    func showOriginalTextViewBy(subtitle: UIViewController, attributedString: NSAttributedString) {
        showOriginalTextView(attributedString)
    }
    func showToast(text: String) {
        UDToast.showTips(with: text, on: self.view)
    }
    func showRefreshViewBy(subtitle: UIViewController) {
        self.showRefreshView()
    }
    func hideHeaderBy(subtitle: UIViewController) {
        self.pagingView.hideHeader()
    }

    func didTappedText(_ startTime: String) {
        guard let time = Int(startTime) else { return }
        transcriptProgressBar?.updateSliderOffset(time)
    }

    func didFinishedEdit() {
        viewModel.minutes.data.fetchSpeakers()
    }
}

extension MinutesDetailViewController: MinutesSubtitlesViewDataProvider {
    func switchToDetailTab() {
        selectItem(with: .text)
    }

    func subtitlesViewVisbleHeight() -> CGFloat {
        return pagingView.bounds.height - CGFloat(segmentHeight) - titleViewVisbleHeight()
    }
    
    func currentTranslateLanguage() -> String {
        return currentTranslationChosenLanguage.code
    }

    func titleViewVisbleHeight() -> CGFloat {
        return titleViewHeight - pagingView.mainScrollView.contentOffset.y
    }

    func videoControlViewHeight() -> CGFloat {
        return videoControlView.frame.height
    }

    func translationChosenLanguage() -> String {
        return self.currentTranslationChosenLanguage.name
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
        return self.isSearching
    }
}

//
//  MinutesDetailViewController+Summary.swift
//  Minutes
//
//  Created by panzaofeng on 2022/1/20.
//

import MinutesFoundation
import MinutesNetwork

extension MinutesDetailViewController: MinutesSummaryViewControllerDelegate {
    func showOriginalTextViewBy(summary: UIViewController, attributedString: NSAttributedString) {
        self.showOriginalTextView(attributedString)
    }
}


extension MinutesDetailViewController: MinutesSpeakersTabDelegate {
    func reloadSegment(_ count: Int) {
        titles = pages.map({ page in
            if page.pageType == .speaker {
                return "\(page.pageType.title)(\(count))"
            } else {
                return page.pageType.title
            }
        })
        reloadSegmentedData()
    }

    func addSpeakerDetail(_ module: MinutesSpeakerDetailModule, mask: UIView) {
        if traitCollection.horizontalSizeClass == .regular {
            module.closeAction = { [weak self] in
                self?.dismiss(animated: true)
            }
            let controller = UIViewController()
            controller.modalPresentationStyle = .formSheet
            controller.view.addSubview(module)
            module.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            userResolver.navigator.present(controller, from: self)
        } else {
            module.closeAction = { [weak module] in
                module?.removeFromSuperview()
            }
            view.addSubview(module)
            module.configureHeader(with: view.bounds.width)

            if isVideo {
                module.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalToSuperview().offset(self.videoViewHeight+8)
                }
            } else {
                module.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalToSuperview().offset(self.pagingView.frame.minY + CGFloat(self.segmentHeight) + self.titleViewHeight)
                }
            }
            view.addSubview(mask)
            mask.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(module.snp.top)
            }
        }

        tracker.tracker(name: .playbarClipView, params: [:])
    }

    func selectSpeaker(_ speakerName: String, time: CGFloat, isEnd: Bool) {
        if isEnd {
            videoView?.hideSpeaker()
        } else {
            let formatTime = TimeInterval(time / 1000).autoFormat() ?? ""
            videoView?.showSpeaker(speakerName, time: formatTime)
        }
    }

    func getCurrentTranslationChosenLanguage() -> Language {
        return currentTranslationChosenLanguage
    }

    func showOriginalSpeakerSummary(attributedString: NSAttributedString) {
        var useAnimation: Bool = true
        if let previous = originalTextView {
            previous.removeFromSuperview()
            useAnimation = false
        }
        animateOriginalTextView(useAnimation, attributedString: attributedString)
    }
}


extension MinutesDetailViewController: MinutesChapterTabDelegate {
    func didFetchedChapters(_ chapters: [MinutesChapterInfo]) {
        videoView?.videoDuration = minutes.basicInfo?.duration ?? 0
        videoView?.chapters = chapters

        videoControlView.videoDuration = minutes.basicInfo?.duration ?? 0
        videoControlView.chapters = chapters

        transcriptProgressBar?.videoDuration = minutes.basicInfo?.duration ?? 0
        transcriptProgressBar?.chapters = chapters
    }

    func getCurTranslationChosenLanguage() -> Language {
        return currentTranslationChosenLanguage
    }

    func didSelectChapter(_ time: Int) {
        transcriptProgressBar?.updateSliderOffset(time)
    }
}

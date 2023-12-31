//
//  MinutesVideoPlayer+subtitles.swift
//  Minutes
//
//  Created by lvdaqian on 2021/2/1.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

class MinutesSubtitlePlayer {
    lazy var subtitleView: MinutesSubtitleRenderView = {
        let subtitleView: MinutesSubtitleRenderView = MinutesSubtitleRenderView()
        return subtitleView
    }()

    var shouldShown: Bool = false
    weak var fatherView: UIView?

    var minutes: Minutes

    var isShown: Bool {
        if subtitleView.superview != nil && subtitleView.isHidden == false {
            return true
        }
        return false
    }

    var isEmpty: Bool {
        let data = minutes.translateData?.subtitleData ?? minutes.data.subtitleData
        return data.isEmpty
    }

    init(fatherView: UIView, minutes: Minutes) {
        self.fatherView = fatherView
        self.minutes = minutes
    }

    deinit {
        let view = subtitleView
        DispatchQueue.main.async {
            view.removeFromSuperview()
        }
    }

    func play(_ playTime: PlaybackTime) {
        let time = playTime.time.millisecond
        let data = minutes.translateData?.subtitleData ?? minutes.data.subtitleData
        DispatchQueue.main.async {
            let firstLine = data.fistline(time)
            let secondLine = data.secondLine(time)
            let model = SubtitleRenderModel(firstLine: firstLine, secondLine: secondLine)
            self.subtitleView.update(model)
        }
    }

    func openSubtitle() {
        guard shouldShown else { return }
        subtitleView.append(to: fatherView)
        subtitleView.isHidden = false
    }

    func showSubtitle() {
        guard shouldShown else { return }
        if subtitleView.superview == nil {
            subtitleView.append(to: fatherView)
        }
        subtitleView.isHidden = false
    }

    func hideSubtitle() {
        subtitleView.isHidden = true
    }

    func updateSubtitle() {
        subtitleView.updateLandscapeStyle()
        subtitleView.updateSubtitleStyle()
    }
}

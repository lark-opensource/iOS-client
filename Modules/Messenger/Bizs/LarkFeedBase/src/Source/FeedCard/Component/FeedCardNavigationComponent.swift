//
//  FeedCardNavigationComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import LarkZoomable

// MARK: - Factory
public class FeedCardNavigationFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .navigation
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardNavigationComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardNavigationComponentView()
    }
}

// MARK: - ViewModel
final class FeedCardNavigationComponentVM: FeedCardBaseComponentVM, FeedCardLineHeight {
    // 组件类别
    var type: FeedCardComponentType {
        return .navigation
    }

    var height: CGFloat {
        teamNames.isEmpty ? 0 : FeedCardNavigationComponentView.Cons.teamHeight
    }

    // VM 数据
    let isShowNavigation: Bool
    let teamNames: [String]

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        teamNames = feedPreview.chatFeedPreview?.teamEntity.teamsName ?? []
        isShowNavigation = !teamNames.isEmpty
    }
}

// MARK: - View
class FeedCardNavigationComponentView: FeedCardBaseComponentView {
    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    var layoutInfo: LarkOpenFeed.FeedCardComponentLayoutInfo? {
        return nil
    }

    // 组件类别
    var type: FeedCardComponentType {
        return .navigation
    }

    let teamFont = FeedCardNavigationComponentView.Cons.teamFont
    func creatView() -> UIView {
        let teamView = FeedTeamView(font: teamFont)
        return teamView
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? FeedTeamView,
              let vm = vm as? FeedCardNavigationComponentVM else { return }
        view.isHidden = !vm.isShowNavigation
        view.setModel(teams: vm.teamNames, font: teamFont)
    }

    enum Cons {
        private static var _zoom: Zoom?
        private static var _teamHeight: CGFloat = 0
        static var teamFont: UIFont { UIFont.ud.body2 }
        static var teamHeight: CGFloat {
            if Zoom.currentZoom != _zoom {
                _zoom = Zoom.currentZoom
                _teamHeight = teamFont.figmaHeight
            }
            return _teamHeight
        }

        static var teamColor: UIColor { UIColor.ud.N900 }
        static var teamRightDistance: CGFloat = 22
    }
}

final class FeedTeamView: UIView {
    private var teams: [String] = []
    private var viewWidth: CGFloat = 0

    private lazy var teamNameView: FeedTeamNameView = {
        return FeedTeamNameView()
    }()

    private lazy var teamImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.LarkFeedBase.feedTeamOutline
        return imageView
    }()

    let font: UIFont
    init(font: UIFont) {
        self.font = font
        super.init(frame: .zero)
        self.addSubview(teamNameView)
        self.addSubview(teamImage)
        teamImage.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(12)
            make.height.equalTo(12)
        }
        teamNameView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalTo(teamImage.snp.trailing).offset(6)
            make.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.width != viewWidth {
            setModel(teams: teams, font: font)
            viewWidth = self.bounds.width
        }
    }

    func setModel(teams: [String], font: UIFont) {
        self.teams = teams
        teamNameView.setModel(teams: teams, font: font)
    }
}

final class FeedTeamNameView: UIView {
    private struct FeedTeamInfo {
        let index: Int
        let width: CGFloat
        let teamName: String
    }

    private let minLength: CGFloat = 56
    private let space: CGFloat = 13
    private let padding: CGFloat = 6
    private var teamLabels: [UILabel] = []
    private var teamInfos: [FeedTeamInfo] = []
    private var labelPool: [UILabel] = []
    private var imagePool: [UILabel] = []
    private var imageStorage: [UILabel] = []
    private var teams: [String] = []
    private var viewWidth: CGFloat = 0
    private var ellipsisLength: CGFloat = 0
    private let ellipsis: String = "..."
    private var hasMoreLength: CGFloat = 0

    func setModel(teams: [String], font: UIFont) {
        ellipsisLength = textWidth(text: ellipsis, font: font)
        hasMoreLength = space + ellipsisLength
        self.teams = teams
        for label in teamLabels {
            label.snp.removeConstraints()
            label.removeFromSuperview()
            if labelPool.count <= 5 {
                labelPool.append(label)
            }
        }
        for label in imageStorage {
            label.snp.removeConstraints()
            label.removeFromSuperview()
            if imagePool.count <= 5 {
                imagePool.append(label)
            }
        }
        imageStorage = []
        teamLabels = []
        teamInfos = []

        var limit: CGFloat = 0
        var sumSqrtTextLength: Double = 0
        for i in 0 ..< teams.count {
            let minWidth = textWidth(text: teams[i], font: font)
            limit += min(minWidth, minLength)
            if limit > (i == teams.count - 1 ? self.bounds.width : self.bounds.width - hasMoreLength) {
                teamInfos.append(FeedTeamInfo(index: i, width: ellipsisLength, teamName: ellipsis))
                let hasMoreLabel = getLabel(font: font)
                teamLabels.append(hasMoreLabel)
                self.addSubview(hasMoreLabel)
                sumSqrtTextLength += sqrt(ellipsisLength)
                break
            }
            limit += space
            teamInfos.append(FeedTeamInfo(index: i, width: minWidth, teamName: teams[i]))
            let teamLabel = getLabel(font: font)
            teamLabels.append(teamLabel)
            self.addSubview(teamLabel)
            sumSqrtTextLength += sqrt(minWidth)
        }
        makeConstraints(sumSqrtTextLength: sumSqrtTextLength, font: font)
    }

    func makeConstraints(sumSqrtTextLength: Double, font: UIFont) {
        guard sumSqrtTextLength != 0 else { return }
        var denominator = sumSqrtTextLength
        teamInfos = teamInfos.sorted(by: { $0.width < $1.width })
        var sumSpace = Double(teamInfos.count - 1) * Double(space)
        var remainWidth = self.bounds.width - sumSpace

        for info in teamInfos {
            let i = info.index
            if remainWidth <= 0 || denominator <= 0 {
                break
            }
            let text: String
            let realWidth: CGFloat
            (text, realWidth) = cropString(text: info.teamName, remainWidth: remainWidth, sum: denominator, width: info.width, font: font)
            teamLabels[i].text = text
            remainWidth -= realWidth
            denominator -= sqrt(info.width)
            teamLabels[i].snp.makeConstraints { (make) in
                if i == 0 {
                    make.leading.equalToSuperview()
                }
                make.width.equalTo(realWidth)
                make.centerY.equalToSuperview()
                make.height.equalTo(20)
            }
            if i != teamLabels.count - 1 {
                let image = getImage()
                imageStorage.append(image)
                self.addSubview(image)
                image.snp.makeConstraints { (make) in
                    make.leading.equalTo(teamLabels[i].snp.trailing).offset(padding)
                    make.trailing.equalTo(teamLabels[i + 1].snp.leading).offset(-padding)
                    make.width.equalTo(1)
                    make.height.equalTo(12)
                    make.centerY.equalToSuperview()
                }
            }
        }
    }

    private func cropString(text: String, remainWidth: Double, sum: Double, width: CGFloat, font: UIFont) -> (String, CGFloat) {
        let ratio = sqrt(width) / sum
        let result = CGFloat(remainWidth * ratio)

        if result >= width || minLength >= width {
            return (text, width)
        } else {
            var standWidth = max(minLength, result)
            var subString = ""
            for char in text {
                if textWidth(text: subString + String(char) + ellipsis, font: font) < standWidth {
                    subString.append(char)
                } else {
                    subString += ellipsis
                    break
                }
            }
            return (subString, textWidth(text: subString, font: font))
        }
    }

    private func textWidth(text: String, font: UIFont) -> CGFloat {
        var size: CGRect
        let textSize = CGSize(width: CGFloat.infinity, height: font.figmaHeight)
        let lineHeight = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight
        size = (text as NSString).boundingRect(with: textSize,
                                               options: [.usesLineFragmentOrigin],
                                               attributes: [
                                                .font: font,
                                                .baselineOffset: baselineOffset,
                                                .paragraphStyle: mutableParagraphStyle
                                               ],
                                               context: nil)
        return ceil(size.width)
    }

    private func getLabel(font: UIFont) -> UILabel {
        guard let label = labelPool.last else {
            let label = UILabel()
            label.font = font
            label.backgroundColor = .clear
            label.textColor = UIColor.ud.textTitle
            return label
        }
        return labelPool.remove(at: labelPool.count - 1)
    }

    private func getImage() -> UILabel {
        guard let label = imagePool.last else {
            let label = UILabel()
            label.backgroundColor = UIColor.ud.lineDividerDefault
            return label
        }
        return imagePool.remove(at: imagePool.count - 1)
    }
}

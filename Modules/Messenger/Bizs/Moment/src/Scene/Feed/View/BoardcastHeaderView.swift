//
//  PlacedPostHeaderView.swift
//  Moment
//
//  Created by zc09v on 2021/3/5.
//

import UIKit
import Foundation
import SnapKit
import EENavigator
import LarkLocalizations
import UniverseDesignTheme
import LarkUIKit
import LKCommonsLogging

protocol BoardcastHeaderViewDelegate: AnyObject {
    func tapPlaced(postId: String)
}

final class BoardcastHeaderView: UIView, SingleBoardcastViewDelegate {
    private static let logger = Logger.log(BoardcastHeaderView.self, category: "BoardcastHeaderView")
    weak var delegate: (BoardcastHeaderViewDelegate & FeedListDependencyDataDelegate)?
    private let boardcastContainer: UIView = UIView()
    private let topPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 12
    private let bottomBlank: CGFloat = 8
    private let titleHeight: CGFloat = 18
    //“精选动态”文案
    private lazy var titleImageView: UIImageView = {
        let view = UIImageView()
        switch LanguageManager.currentLanguage {
        case .zh_CN:
            view.image = Resources.placedPostHeaderPinned_CN
        default:
            view.image = Resources.placedPostHeaderPinned_overseas
        }
        return view
    }()
    var mainMargin: CGFloat = 16 {
        didSet {
            backGroundImageView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(mainMargin)
            }
            boardcastContainer.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(mainMargin)
                make.right.equalToSuperview().offset(-mainMargin)
            }
            titleImageView.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(mainMargin + 12)
            }
        }
    }
    private var boardcastContentHeight: CGFloat = 0
    private var boardcastViews: [UIView] = []
    private let backgroundImage = { () -> UIImage in
        if #available(iOS 13.0, *),
           UDThemeManager.getRealUserInterfaceStyle() == .dark {
            return Resources.placedPostHeaderBack_dark
        }
        return Resources.placedPostHeaderBack_light
    }

    private lazy var backGroundImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    var totalWidth: CGFloat?
    var totalHeight: CGFloat {
        return topPadding + bottomPadding + titleHeight + boardcastContentHeight + bottomBlank
    }

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.clear
        self.addSubview(backGroundImageView)
        backGroundImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(mainMargin)
        }
        self.addSubview(titleImageView)
        titleImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topPadding)
            make.left.equalToSuperview().offset(mainMargin + 12)
            make.height.equalTo(titleHeight)
        }
        self.addSubview(boardcastContainer)
        boardcastContainer.snp.makeConstraints { (make) in
            make.top.equalTo(titleImageView.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(mainMargin)
            make.right.equalToSuperview().offset(-mainMargin)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI(boardcasts: [RawData.Broadcast], totalWitdh: CGFloat) {
        for boardcastView in boardcastViews {
            boardcastView.removeFromSuperview()
        }
        boardcastViews = []
        boardcastContentHeight = 10
        var lastBoardcastView: SingleBoardcastView?
        for (index, boardcast) in boardcasts.enumerated() {
            let boardcastView = SingleBoardcastView(boardcast: boardcast)
            boardcastView.delegate = self
            boardcastContainer.addSubview(boardcastView)
            if let lastBoardcastView = lastBoardcastView {
                boardcastView.snp.makeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.height.equalTo(22)
                    make.top.equalTo(lastBoardcastView.snp.bottom).offset(8)
                    if index == boardcasts.count - 1 {
                        make.bottom.equalToSuperview()
                    }
                }
                boardcastContentHeight += 30
            } else {
                boardcastView.snp.makeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.top.equalToSuperview()
                    make.height.equalTo(22)
                    if index == boardcasts.count - 1 {
                        make.bottom.equalToSuperview()
                    }
                }
                boardcastContentHeight += 22
            }
            lastBoardcastView = boardcastView
            boardcastViews.append(boardcastView)
        }
        self.updateBackGroudImage(totalWitdh: totalWitdh)
    }

    func tapPlaced(postId: String) {
        MomentsTracer.trackFeedPageViewClick(.top,
                                             circleId: delegate?.requestForCircleId(),
                                             postId: postId,
                                             type: .recommendTab,
                                             detail: nil)
        self.delegate?.tapPlaced(postId: postId)
    }

    func updateBackGroudImage(totalWitdh: CGFloat?) {
        if totalWitdh != nil {
            self.totalWidth = totalWitdh
        }
        guard let totalWitdh = self.totalWidth else {
            return
        }
        let imageTotalWitdh = totalWitdh - 2 * mainMargin
        let backgroundImage = self.backgroundImage()
        let origin_width: CGFloat = backgroundImage.size.width
        let origin_height: CGFloat = backgroundImage.size.height
        let ratio = imageTotalWitdh / origin_width
        let width = origin_width * ratio
        let height = origin_height * ratio

        guard width > 0, height > 0 else {
            Self.logger.error("updateBackGroudImage - totalWitdh:\(totalWitdh) width: \(width) height: \(height)")
            return
        }
        /// 该方法不能接受参数为负值 否则crash
        /// 这个方法不赋值，背景色为白色 不影响使用
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        backgroundImage.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let scaleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageTotalHeight = self.totalHeight - bottomBlank
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: imageTotalHeight))
        if let cropCGImage = scaleImage?.cgImage?.cropping(to: path.bounds) {
            backGroundImageView.image = UIImage(cgImage: cropCGImage)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateBackGroudImage(totalWitdh: nil)
    }
}

protocol SingleBoardcastViewDelegate: BoardcastHeaderViewDelegate {
}

final class SingleBoardcastView: UIView {
    weak var delegate: SingleBoardcastViewDelegate?
    private let dot: UIView = UIView()
    private let contentLabel: UILabel = UILabel()
    private let boardcast: RawData.Broadcast

    init(boardcast: RawData.Broadcast) {
        self.boardcast = boardcast
        super.init(frame: .zero)
        dot.backgroundColor = UIColor.ud.B600
        dot.layer.cornerRadius = 2
        dot.layer.masksToBounds = true
        self.addSubview(dot)
        dot.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(4)
        }

        contentLabel.font = UIFont.systemFont(ofSize: 14)
        contentLabel.textColor = UIColor.ud.N900
        contentLabel.numberOfLines = 1
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentLabel.text = boardcast.title
        self.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(dot.snp.right).offset(4)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }

        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func handleTap() {
        self.delegate?.tapPlaced(postId: boardcast.postID)
    }
}

final class BoardcastHeaderContainerView: UIView {
    override var frame: CGRect {
        didSet {
            if Display.pad {
                super.frame = MomentsViewAdapterViewController.computeCellFrame(originFrame: frame)
            }
        }
    }
}

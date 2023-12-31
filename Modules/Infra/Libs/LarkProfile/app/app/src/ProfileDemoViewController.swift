//
//  ProfileDemoViewController.swift
//  LarkProfileDev
//
//  Created by Hayden Wang on 2021/6/29.
//

import Foundation
import UIKit
import LarkProfile

class ProfileDemoViewController: UIViewController {

    var profileView: ProfileDemoView {
        if let profileView = view as? ProfileDemoView {
            return profileView
        } else {
            let profileView = ProfileDemoView()
            view = profileView
            return profileView
        }
    }

    public override func loadView() {
        view = ProfileDemoView()
    }

    private var segmentedTableView: SegmentedTableView {
        return profileView.segmentedView
    }

    private var headerImageView: UIImageView {
        return profileView.backgroundImageView
    }

    private var imageHeight: CGFloat {
        ceil(UIScreen.main.bounds.width / 16 * 9)
    }
    // 防止侧滑的时候透明度变化
    private var currentProgress: CGFloat = 0

    private var naviHeight: CGFloat {
        let barHeight = navigationController?.navigationBar.frame.height ?? 44
        return UIApplication.shared.statusBarFrame.height + barHeight
    }

    private lazy var expandButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.bgFloat
        button.setTitle("Expand", for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.addTarget(self, action: #selector(didtapExpandButton), for: .touchUpInside)
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var tagsButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.bgFloat
        button.setTitle("Tags", for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.addTarget(self, action: #selector(didtapTagsButton), for: .touchUpInside)
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        return button
    }()

    @objc
    private func didtapExpandButton() {
        profileView.statusLabel.text = String(
            repeating: "Talk is cheap, show me the code. ",
            count: Int.random(in: 0...20)
        )
        segmentedTableView.updateHeaderViewFrame()
    }

    private lazy var scalableTag: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.green.withAlphaComponent(0.3)
        return view
    }()

    var counter: Int = 0

    @objc
    private func didtapTagsButton() {
//        profileView.tagContainer.isHidden.toggle()

        // swiftlint:disable all
        let count = [5, 10, 15][counter % 3]
        let company = String(repeating: "字节跳动", count: count)
        counter += 1
        // swiftlint:enable all

        let text = String(repeating: "乔夏木", count: Int.random(in: 1...20))
        let name = NSAttributedString(
            string: text,
            attributes: [.font: UIFont.ud.title0]
        )
        profileView.nameLabel.attributedText = name
        segmentedTableView.updateHeaderViewFrame()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.segmentedTableView.updateHeaderViewFrame()
        }

//        print(profileView.nameLabel.lastLineWidth)
        let width = profileView.nameLabel.frame.width
        let remaining = width - lastLineMaxX(message: name, labelWidth: width)

        scalableTag.removeFromSuperview()
        profileView.addSubview(scalableTag)
        scalableTag.snp.remakeConstraints { make in
            make.bottom.trailing.equalTo(profileView.nameLabel)
            make.height.equalTo(profileView.nameLabel.font.lineHeight)
            make.width.equalTo(remaining)
        }
    }

    public func lastLineMaxX(message: NSAttributedString, labelWidth: CGFloat) -> CGFloat {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let labelSize = CGSize(width: labelWidth, height: .infinity)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: labelSize)
        let textStorage = NSTextStorage(attributedString: message)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0

        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: message.length - 1)
        let lastLineFragmentRect = layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex,
                                                                      effectiveRange: nil)

        return lastLineFragmentRect.maxX
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.alpha = currentProgress
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.alpha = 1.0
    }

    private lazy var viewControllers: [SegmentedTableViewContentable] = {
        [
            TableContentController(num: 30),
            TableContentController(num: 5),
            TableContentController(num: 9),
            CollectionContentController(),
            ScrollContentController()
        ]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        segmentedTableView.hoverHeight = naviHeight
        segmentedTableView.delegate = self
        segmentedTableView.setViewControllers(viewControllers)
        segmentedTableView.setHeaderView(profileView.headerView)
        headerImageView.image = UIImage(named: "bg_image")
        profileView.avatarView.image = UIImage(named: "header_img")
        addButtons([expandButton, tagsButton])
        profileView.tagView.maxTagCount = 10
        profileView.tagView.setTags([.connect, .doNotDisturb, .robot, .public])
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        segmentedTableView.updateHeaderViewFrame()
    }

    deinit {
        print("DemoViewController deinit")
    }

    func addButtons(_ buttons: [UIButton]) {
        profileView.buttonsStack.subviews.forEach {
            $0.removeFromSuperview()
        }
        for button in buttons {
            button.snp.makeConstraints { make in
                make.height.equalTo(54)
            }
            profileView.buttonsStack.addArrangedSubview(button)
        }
    }
}

extension ProfileDemoViewController: SegmentedTableViewDelegate {

    func segmentedView(_ view: SegmentedTableView, didSelectTabAt index: Int) {
        print("切换到 Tab\(index)")
    }

    // MARK: 滚动代理方法
    func segmentedViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        // Header Image 吸顶效果
        headerImageView.snp.updateConstraints { update in
            update.top.equalToSuperview().offset(min(0, offsetY))
        }

//        var headerImageViewY: CGFloat = offsetY
//        var headerImageViewH: CGFloat = headerHeight - offsetY
//        if offsetY <= 0.0 {
//            navigationController?.navigationBar.alpha = 0
//            currentProgress = 0.0
//        } else {
//            headerImageViewY = 0
//            headerImageViewH = headerHeight
//
//            let adjustHeight: CGFloat = headerHeight - navHeight
//            let progress = 1 - (offsetY / adjustHeight)
//
//            //设置导航栏透明度
//            navigationController?.navigationBar.alpha = 1 - progress
//            currentProgress = 1 - progress
//        }
//        headerImageView.frame.origin.y = headerImageViewY
//        headerImageView.frame.size.height = headerImageViewH
    }
}

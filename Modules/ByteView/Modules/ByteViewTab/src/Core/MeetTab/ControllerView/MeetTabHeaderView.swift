//
//  MeetTabHeaderView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import Foundation
import RxSwift
import Action
import ByteViewCommon

class MeetTabHeaderView: UIView {

    enum Layout {
        static let itemPadWidth: CGFloat = 162.0
        static let itemPadHeight: CGFloat = 126.0
        static let itemPadBreakedHeight: CGFloat = 148.0
    }

    var estimatedHeight: CGFloat {
        itemsHeight + bottomInset
    }

    // 是否展示电话服务开通引导页，仅当开关关闭时候且为飞书包才会出现
    var isShowGuideView: Bool = false

    lazy var buttons: [MeetTabHeaderButtonType] = {
        var buttons: [MeetTabHeaderButtonType] = [.newMeeting, .joinMeeting, .schedule]
        if viewModel.fg.isTabMinutesEnabled {
            buttons.append(.minutes)
        }
        let (showPhoneButton, showGuide) = viewModel.phoneCallConfig(isAuthorized: (viewModel.setting.isEnterprisePhoneEnabled), isScopyAny: (viewModel.setting.enterprisePhoneConfig.scopeAny))
        isShowGuideView = showGuide
        if showPhoneButton {
            buttons.append(.phoneCall)
        }
        return buttons
    }()
    lazy var containerView: UICollectionView = {
        let containerView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        containerView.backgroundColor = .ud.bgBody
        containerView.delaysContentTouches = false
        containerView.isScrollEnabled = false
        containerView.register(MeetTabHeaderButton.self, forCellWithReuseIdentifier: MeetTabHeaderButton.description())
        containerView.register(MeetTabHeaderPadButton.self, forCellWithReuseIdentifier: MeetTabHeaderPadButton.description())
        return containerView
    }()

    var actions: [MeetTabHeaderButtonType: CocoaAction] = [:]
    let viewModel: MeetTabViewModel
    init(frame: CGRect, viewModel: MeetTabListViewModel) {
        self.viewModel = viewModel.tabViewModel
        super.init(frame: frame)

        backgroundColor = Display.pad ? UIColor.ud.bgContentBase : UIColor.ud.bgBase

        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.size.equalToSuperview()
        }
        updateLayout()

        containerView.dataSource = self
        containerView.reloadData()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    private func updateLayout() {
        containerView.setCollectionViewLayout(flowLayout, animated: false)
        if isRegular {
            containerView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
                $0.width.equalToSuperview()
            }
        } else {
            containerView.snp.remakeConstraints {
                $0.top.left.right.equalToSuperview()
                $0.width.equalToSuperview()
                $0.bottom.equalToSuperview().inset(bottomInset)
                $0.height.equalTo(containerView.contentSize.height).priority(.low)
            }
        }
        containerView.reloadData()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension MeetTabHeaderView {
    var isRegular: Bool {
        return MeetTabTraitCollectionManager.shared.isRegular
    }

    var maxButtonNumberInSingleLine: Int {
        if Util.isIpadFullScreen && !isRegular {
            return 5
        } else {
            return 4
        }
    }

    var isExtent: Bool {
        let styleConfig: VCFontConfig = .assist
        let estimatedWidth: CGFloat = itemWidth - 4
        return MeetTabHeaderButtonType.allCases.contains {
            NSString(string: $0.title).boundingRect(with: CGSize(width: estimatedWidth, height: .greatestFiniteMagnitude),
                                                    options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                    attributes: styleConfig.toAttributes(),
                                                    context: nil).height > styleConfig.lineHeight
        }
    }

    var isTitleBreaked: Bool {
        let styleConfig: VCFontConfig = .hAssist
        let estimatedWidth: CGFloat = Layout.itemPadWidth - 2 * 20
        return MeetTabHeaderButtonType.allCases.contains {
            NSString(string: $0.title).boundingRect(with: CGSize(width: estimatedWidth, height: .greatestFiniteMagnitude),
                                                    options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                    attributes: styleConfig.toAttributes(),
                                                    context: nil).height > styleConfig.lineHeight
        }
    }

    var flowLayout: UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.sectionInset = sectionInset
        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = spacing
        return flowLayout
    }

    var itemWidth: CGFloat {
        let count = min(buttons.count, maxButtonNumberInSingleLine)
        return (bounds.width - sectionInset.left - sectionInset.right) / CGFloat(count)
    }

    var itemsHeight: CGFloat {
        #if compiler(>=5.5)
        return ceil(Double(buttons.count) / Double(maxButtonNumberInSingleLine)) * itemSize.height
        #else
        return ceil(CGFloat(buttons.count) / CGFloat(maxButtonNumberInSingleLine)) * itemSize.height
        #endif
    }

    var itemSize: CGSize {
        if isRegular {
            return CGSize(width: Layout.itemPadWidth, height: isTitleBreaked ? Layout.itemPadBreakedHeight : Layout.itemPadHeight)
        } else {
            return CGSize(width: itemWidth, height: isExtent ? 108.0 : 90.0)
        }
    }

    var sectionInset: UIEdgeInsets {
        if isRegular {
            return UIEdgeInsets(top: 16.0, left: 18.0, bottom: 0.0, right: 17.0)
        } else if Util.isIpadFullScreen {
            return UIEdgeInsets(top: 0.0, left: 40.0, bottom: 0.0, right: 40.0)
        } else if Util.isSplit, UIApplication.shared.statusBarOrientation.isPortrait {
            return UIEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
        } else {
            return UIEdgeInsets(top: 0.0, left: 4.0, bottom: 0.0, right: 4.0)
        }
    }

    var spacing: CGFloat {
        if isRegular {
            return 16.0
        } else {
            return 0.0
        }
    }

    var bottomInset: CGFloat {
        if isRegular {
            return 0.0
        } else if Util.isIpadFullScreen {
            return 8.0
        } else {
            return 12.0
        }
    }
}

extension MeetTabHeaderView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buttons.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        let headerType = buttons[indexPath.row]
        if isRegular {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: MeetTabHeaderPadButton.description(), for: indexPath)
            let configer: MeetTabHeaderPadButton? = cell as? MeetTabHeaderPadButton
            configer?.bind(to: headerType)
            configer?.button.rx.action = actions[headerType]
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: MeetTabHeaderButton.description(), for: indexPath)
            let configer: MeetTabHeaderButton? = cell as? MeetTabHeaderButton
            configer?.bind(to: headerType)
            configer?.button.rx.action = actions[headerType]
        }
        return cell
    }
}

extension MeetTabViewModel {
    func phoneCallConfig(isAuthorized: Bool, isScopyAny: Bool) -> (Bool, Bool) {
        if Display.pad { return (false, false) }
        if self.setting.isFeishuBrand {
            // https://bytedance.feishu.cn/docx/doxcnaWECy3oLwIj109dV3lpCdA
            // 飞书品牌下如果FG未开，不展示入口
            if !self.fg.isPhoneServiceEnabled {
                return (false, false)
            } else if isAuthorized {
                return (isScopyAny ? (true, false) : (false, false))
            } else {
                return (true, true)
            }
        } else {
            return (isAuthorized && isScopyAny, false)
        }
    }
}

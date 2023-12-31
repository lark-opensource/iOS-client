//
//  ThreadDeleteMenuController.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/5/26.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkMessageCore
import RustPB
import FigmaKit

enum ThreadMenuType {
    /// 删除话题
    case delete
    /// pin/unpin 话题
    case pin(Bool)
    /// top/untop 话题
    case topThread(Bool)
    /// 分享话题
    case shareTopic
    /// 标记话题状态
    case markTopic(RustPB.Basic_V1_ThreadState)
    /// 转发
    case forward
    /// 不看该帖子
    case dislikeThisTopic
    /// 不看X发送的帖子
    case dislikeTopicFromAuthor(name: String)
    /// 不看来自X小组的帖子
    case dislikeTopicFromTopicGroup(name: String)
    /// 任务
    case todo
    /// 订阅话题
    case subscribe
    /// 取消订阅
    case unsubscribe
    /// 消息免打扰
    case muteMsgNotice
    /// 打开消息通知
    case msgNotice
}

typealias ThreadActionFunc = (ThreadMenuType) -> Void

final class ThreadFloatMenuController: BaseUIViewController {
    private let backgroundColor: UIColor = UIColor.ud.bgMask
    private let bgView: UIView = UIView()
    private let menuView: ThreadMenuView
    private let pointView: UIView

    var animationBegin: (() -> Void)?
    var animationEnd: (() -> Void)?

    init(pointView: UIView,
         itemTypes: [ThreadMenuType],
         actionFunc: @escaping ThreadActionFunc) {
        self.pointView = pointView
        self.menuView = ThreadMenuView()
        super.init(nibName: nil, bundle: nil)

        let itemsActionFunc: ThreadActionFunc = { [weak self] (type) in
            self?.hide(completion: { actionFunc(type) })
        }

        var items = [MenuInfo]()
        for type in itemTypes {
            switch type {
            case .shareTopic:
                items.append(
                    MenuInfo(
                        icon: Resources.menu_shareTopic,
                        title: BundleI18n.LarkThread.Lark_Chat_TopicToolShare,
                        type: .shareTopic,
                        acionFunc: itemsActionFunc
                    )
                )
            case .pin(let isPin):
                items.append(
                    MenuInfo(
                        icon: isPin ? Resources.menu_unPin : Resources.menu_pin,
                        title: isPin ?
                            BundleI18n.LarkThread.Lark_Pin_UnpinButton : BundleI18n.LarkThread.Lark_Pin_PinButton,
                        type: .pin(isPin),
                        acionFunc: itemsActionFunc
                    )
                )
            case .topThread(let isTop):
                items.append(
                    MenuInfo(
                        icon: isTop ? Resources.menu_top : Resources.menu_cancelTop,
                        title: isTop ?
                        BundleI18n.LarkThread.Lark_IMChatPin_PinTopic_Option : BundleI18n.LarkThread.Lark_IMChatPin_RemovePin_Option,
                        type: .topThread(isTop),
                        acionFunc: itemsActionFunc
                    )
                )
            case .delete:
                items.append(
                    MenuInfo(
                        icon: Resources.thread_delete,
                        title: BundleI18n.LarkThread.Lark_Chat_RecallTopic,
                        type: .delete,
                        acionFunc: itemsActionFunc
                    )
                )
            case .markTopic(let state):
                items.append(
                    MenuInfo(
                        icon: state == .closed ? Resources.thread_menu_repon : Resources.thread_menu_close,
                        title: state == .closed ? BundleI18n.LarkThread.Lark_Chat_TopicToolReopen :
                            BundleI18n.LarkThread.Lark_Groups_TopicToolClose,
                        type: .markTopic(state),
                        acionFunc: itemsActionFunc
                    )
                )
            case .forward:
                items.append(
                    MenuInfo(
                        icon: Resources.thread_foward,
                        title: BundleI18n.LarkThread.Lark_Chat_TopicToolForward,
                        type: .forward,
                        acionFunc: itemsActionFunc
                    )
                )
            case .dislikeThisTopic:
                items.append(
                    MenuInfo(
                        icon: Resources.thread_dislike_topic,
                        title: BundleI18n.LarkThread.Lark_Groups_PostMenuDislike,
                        type: .dislikeThisTopic,
                        acionFunc: itemsActionFunc
                    )
                )
            case let .dislikeTopicFromAuthor(name):
                items.append(
                    MenuInfo(
                        icon: Resources.thread_dislike_author,
                        title: BundleI18n.LarkThread.Lark_Groups_PostMenuDislikeUser,
                        type: .dislikeTopicFromAuthor(name: name),
                        acionFunc: itemsActionFunc
                    )
                )
            case let .dislikeTopicFromTopicGroup(name):
                items.append(
                    MenuInfo(
                        icon: Resources.thread_dislike_group,
                        title: BundleI18n.LarkThread.Lark_Groups_PostMenuDislikeGroup,
                        type: .dislikeTopicFromTopicGroup(name: name),
                        acionFunc: itemsActionFunc
                    )
                )
            case .todo:
                items.append(
                    MenuInfo(
                        icon: Resources.menu_todo,
                        title: BundleI18n.LarkThread.Todo_Task_CreateATask,
                        type: .todo,
                        acionFunc: itemsActionFunc
                    )
                )
            case .subscribe:
                items.append(
                    MenuInfo(
                        icon: Resources.subscribe,
                        title: BundleI18n.LarkThread.Lark_IM_Thread_ThreadDetail_SubscribeToThread_Button,
                        type: .subscribe,
                        acionFunc: itemsActionFunc
                    )
                )
            case .unsubscribe:
                items.append(
                    MenuInfo(
                        icon: Resources.unsubscribe,
                        title: BundleI18n.LarkThread.Lark_IM_Thread_ThreadDetail_UnsubscribeToThread_Button,
                        type: .unsubscribe,
                        acionFunc: itemsActionFunc
                    )
                )

            case .msgNotice:
                items.append(
                    MenuInfo(
                        icon: Resources.muteNoticeIcon,
                        title: BundleI18n.LarkThread.Lark_Feed_MuteNotificationsOffDropdown,
                        type: .msgNotice,
                        acionFunc: itemsActionFunc
                    )
                )
            case .muteMsgNotice:
                items.append(
                    MenuInfo(
                        icon: Resources.noticeIcon,
                        title: BundleI18n.LarkThread.Lark_Core_MuteNotifications_ToggleButton,
                        type: .muteMsgNotice,
                        acionFunc: itemsActionFunc
                    )
                )
            }
        }

        self.menuView.setupActionsViews(menuItems: items)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.clear

        bgView.isUserInteractionEnabled = true
        view.addSubview(bgView)
        bgView.backgroundColor = self.backgroundColor
        bgView.alpha = 0
        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedHandler))
        self.bgView.addGestureRecognizer(tap)

        menuView.frame = originRectOfPointView()
        view.addSubview(menuView)
        menuView.scaleAnimationView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        menuView.alpha = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.animationBegin?()

        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.menuView.frame = self.showRectOfMenuView(by: self.view.bounds.width)
            self.menuView.scaleAnimationView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.menuView.alpha = 1
            self.bgView.alpha = 1
        })
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // 转屏时隐藏菜单
        self.hide()
    }

    @objc
    private func tappedHandler() {
        self.hide()
    }

    private func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.menuView.frame = self.originRectOfPointView()
            self.menuView.scaleAnimationView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.menuView.alpha = 0
            self.view.layoutIfNeeded()
            self.bgView.alpha = 0
        }, completion: { ( _ ) in
            self.animationEnd?()
            self.dismiss(animated: false, completion: {
                completion?()
            })
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func originRectOfPointView() -> CGRect {
        guard let superView = pointView.superview else {
            return .zero
        }

        let rect = superView.convert(pointView.frame, to: superView.window)

        return rect
    }

    private func showRectOfMenuView(by viewWidth: CGFloat) -> CGRect {
        let naviBarMaxY = CGFloat((Display.iPhoneXSeries ? 44 : 20) + 44)

        guard let superView = pointView.superview else {
            return .zero
        }

        let rect = superView.convert(pointView.frame, to: superView.window)
        var y = rect.minY - menuView.heightOfView
        // 如果覆盖到导航栏 则显示在下方
        if y < naviBarMaxY {
            if rect.maxY < naviBarMaxY {
                y = naviBarMaxY
            } else {
                y = rect.maxY
            }
        }

        let x = viewWidth - menuView.widthOfView - 20
        return CGRect(x: x, y: y, width: menuView.widthOfView, height: menuView.heightOfView)
    }
}

private final class ThreadMenuView: UIView {
    private(set) var heightOfView: CGFloat = 96
    private(set) var widthOfView: CGFloat = 0

    private var menuItems = [MenuInfo]()

    var scaleAnimationView = UIView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupBlurEffectView()
        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.cornerRadius = 8
        self.clipsToBounds = true

        self.addSubview(scaleAnimationView)
        scaleAnimationView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    private func setupBlurEffectView() {
        let blurView = VisualBlurView()
        blurView.fillColor = UIColor.ud.bgFloatPush
        blurView.blurRadius = 40
        self.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
    func setupActionsViews(menuItems: [MenuInfo]) {
        self.menuItems = menuItems
        self.heightOfView = MenuItem.heightOfItem * CGFloat(menuItems.count)

        for (index, menuInfo) in self.menuItems.enumerated() {
            let menuItem = MenuItem(info: menuInfo)
            scaleAnimationView.addSubview(menuItem)
            menuItem.snp.makeConstraints({ (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(MenuItem.heightOfItem)
                make.top.equalToSuperview().offset(MenuItem.heightOfItem * CGFloat(index))
            })

            caluMaxWidth(title: menuInfo.title)
        }
    }

    private func caluMaxWidth(title: String) {
        let titleWidth = NSAttributedString(
            string: title,
            attributes: [
                .font: MenuItem.font
            ]
            ).boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: heightOfView),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).size.width.rounded(.up)

        let width = MenuItem.iconLeading + MenuItem.iconWidth + MenuItem.iconAndTitleSpacing + titleWidth + MenuItem.titleTrailing

        if widthOfView < width {
            widthOfView = width
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct MenuInfo {
    let icon: UIImage
    let title: String
    let type: ThreadMenuType
    let acionFunc: ThreadActionFunc
}

private final class MenuItem: UIView {
    static let font = UIFont.systemFont(ofSize: 16)
    static let heightOfItem: CGFloat = 48
    static let iconLeading: CGFloat = 16
    static let iconWidth: CGFloat = 20
    static let iconAndTitleSpacing: CGFloat = 10
    static let titleTrailing: CGFloat = 20

    private let iconImage: UIImageView = UIImageView()
    private let label: UILabel = UILabel()
    private let button: UIButton = MenuItemButton()

    private let menuInfo: MenuInfo

    init(info: MenuInfo) {
        self.menuInfo = info
        super.init(frame: .zero)

        self.addSubview(iconImage)
        iconImage.tintColor = UIColor.ud.iconN1
        iconImage.image = info.icon.withRenderingMode(.alwaysTemplate)
        iconImage.contentMode = .scaleAspectFit
        iconImage.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iconImage.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        iconImage.snp.makeConstraints { (make) in
            make.left.equalTo(MenuItem.iconLeading)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: MenuItem.iconWidth, height: MenuItem.iconWidth))
        }

        self.addSubview(label)
        label.text = info.title
        label.font = MenuItem.font
        label.textColor = UIColor.ud.textTitle
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        label.snp.makeConstraints { (make) in
            make.left.equalTo(iconImage.snp.right).offset(MenuItem.iconAndTitleSpacing)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-MenuItem.titleTrailing)
        }

        self.addSubview(button)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func clickButton() {
        self.menuInfo.acionFunc(menuInfo.type)
    }
    final class MenuItemButton: UIButton {
        private lazy var highLightView: UIView = {
            let highLightView = UIView()
            highLightView.backgroundColor = UIColor.ud.fillHover
            highLightView.layer.cornerRadius = 6.0
            highLightView.isHidden = true
            addSubview(highLightView)
            highLightView.snp.makeConstraints { (make) in
                make.top.left.equalToSuperview().offset(4)
                make.bottom.right.equalToSuperview().offset(-4)
                make.centerY.equalToSuperview()
            }
            return highLightView
        }()
        override var isHighlighted: Bool {
            didSet {
                highLightView.isHidden = !isHighlighted
            }
        }

    }
}

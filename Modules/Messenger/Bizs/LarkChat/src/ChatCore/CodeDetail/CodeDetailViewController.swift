//
//  CodeDetailViewController.swift
//  LarkChat
//
//  Created by Bytedance on 2022/11/7.
//

import UIKit
import Foundation
import SnapKit
import LarkEMM
import LarkCore
import LarkUIKit
import LKRichView
import LarkStorage
import LarkMessageCore
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignColor

/// 代码详情页
class CodeDetailViewController: BaseUIViewController, LKRichViewSelectionDelegate, UIScrollViewDelegate {
    @KVConfig(key: KVKeys.Chat.codeLineBreak, store: KVStores.Chat.global())
    private var codeLineBreak: Bool
    /// 切换换行
    private let switchImage = UIImageView()
    /// 展示代码块
    private lazy var configOptions: ConfigOptions = {
        return ConfigOptions([
            .debug(false),
            .visualConfig(VisualConfig(
                selectionColor: UIColor.ud.colorfulBlue.withAlphaComponent(0.16),
                cursorColor: UIColor.ud.colorfulBlue,
                cursorHitTestInsets: UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25)
            ))
         ])
    }()
    private lazy var richContainerView = LKRichContainerView(frame: .zero, options: self.configOptions)
    /// 代码块超长/宽时，支持左右滚动
    private let richContainerScrollView = UIScrollView()
    private let core = LKRichViewCore()
    /// 复制菜单
    private let copyMenuView = UIView()
    private let viewModel: CodeDetailViewModel

    // MARK: - 生命周期
    init(viewModel: CodeDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        // 配置代码块，放在最下面
        do {
            self.richContainerScrollView.bounces = false
            self.view.addSubview(self.richContainerScrollView)
            self.richContainerScrollView.snp.makeConstraints { make in
                make.top.equalTo(self.viewTopConstraint).offset(48)
                make.bottom.equalTo(self.viewBottomConstraint)
                make.left.equalTo(3)
                make.right.equalTo(-3)
            }
            self.core.load(renderer: self.core.createRenderer(self.viewModel.codeElement))
            // 超出滚动视图则不显示，因为后续的计算逻辑会把滚动视图外的部分计算为用户不可见
            self.richContainerScrollView.clipsToBounds = true
            self.richContainerScrollView.delegate = self
            self.richContainerView.clipsToBounds = false
            self.richContainerView.richView.selectionDelegate = self
            self.richContainerScrollView.addSubview(self.richContainerView)
            // 分片大小设置很小，也会展示空白
            // self.richContainerView.richView.maxTiledSize = UInt(self.view.bounds.size.width * 200)
            self.richContainerView = richContainerView
        }
        // 创建一个占位视图，遮挡RichView多绘制的内容
        do {
            let clipsToBoundsView = UIView()
            clipsToBoundsView.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
            self.view.addSubview(clipsToBoundsView)
            clipsToBoundsView.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.bottom.equalTo(self.viewTopConstraint).offset(48)
            }
        }
        // 配置导航头部视图
        do {
            let navigationView = UIView()
            navigationView.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
            self.view.addSubview(navigationView)
            navigationView.snp.makeConstraints { make in
                make.top.equalTo(self.viewTopConstraint)
                make.left.right.equalToSuperview()
                make.height.equalTo(48)
            }
            // 用户反馈不好点：这个包一层[48, 48]的按钮，扩大点击热区
            let exitButton = UIButton(frame: .zero)
            exitButton.addTarget(self, action: #selector(self.exit(gestureRecognizer:)), for: .touchUpInside)
            do {
                let exitIcon = UIImageView(image: Resources.codeDetailExitIcon.ud.withTintColor(UIColor.ud.iconN1))
                exitButton.addSubview(exitIcon)
                exitIcon.snp.makeConstraints { make in
                    make.size.equalTo(CGSize(width: 24, height: 24))
                    make.center.equalToSuperview()
                }
            }
            navigationView.addSubview(exitButton)
            exitButton.snp.makeConstraints { make in
                make.left.equalTo(4)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 48, height: 48))
            }
            let titleLabel = UILabel()
            titleLabel.text = BundleI18n.LarkChat.Lark_IM_CodeBlock_Title
            titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            titleLabel.textColor = UIColor.ud.textTitle
            navigationView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            // 用户反馈不好点：这个包一层[48, 48]的按钮，扩大点击热区
            let switchButton = UIButton(frame: .zero)
            switchButton.addTarget(self, action: #selector(self.switchLineBreak(gestureRecognizer:)), for: .touchUpInside)
            do {
                self.switchImage.image = (self.codeLineBreak ? Resources.codeDetailOffWrapIcon : Resources.codeDetailOnWrapIcon).ud.withTintColor(UIColor.ud.iconN1)
                switchButton.addSubview(self.switchImage)
                self.switchImage.snp.makeConstraints { make in
                    make.size.equalTo(CGSize(width: 24, height: 24))
                    make.center.equalToSuperview()
                }
            }
            navigationView.addSubview(switchButton)
            switchButton.snp.makeConstraints { make in
                make.right.equalTo(-4)
                make.size.equalTo(CGSize(width: 48, height: 48))
                make.centerY.equalToSuperview()
            }
        }
        // 复制菜单
        do {
            self.copyMenuView.frame = CGRect(origin: .zero, size: CGSize(width: 56, height: 72))
            self.copyMenuView.isUserInteractionEnabled = true
            self.copyMenuView.backgroundColor = UIColor.ud.bgFloat
            self.copyMenuView.layer.cornerRadius = 8
            self.copyMenuView.layer.masksToBounds = false
            self.copyMenuView.layer.shadowOffset = CGSize(width: 0, height: 0)
            self.copyMenuView.layer.shadowOpacity = 1.0
            self.copyMenuView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)
            let copyImage = UDIcon.getIconByKey(.copyOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
            let copyImageView = UIImageView(image: copyImage)
            copyImageView.frame = CGRect(origin: CGPoint(x: 17, y: 16), size: CGSize(width: 22, height: 22))
            self.copyMenuView.addSubview(copyImageView)
            let titleLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: 46), size: CGSize(width: 56, height: 16)))
            titleLabel.text = BundleI18n.LarkChat.Lark_IM_CodeBlockTool_Copy
            titleLabel.font = UIFont.systemFont(ofSize: 11)
            titleLabel.textColor = UIColor.ud.textTitle
            titleLabel.textAlignment = .center
            self.copyMenuView.addSubview(titleLabel)
            self.copyMenuView.isHidden = true
            self.copyMenuView.lu.addTapGestureRecognizer(action: #selector(self.onTapCopyMenuView(gestureRecognizer:)), target: self)
            self.view.addSubview(self.copyMenuView)
        }
        // 长按代码块出现复制菜单
        self.richContainerScrollView.lu.addLongPressGestureRecognizer(action: #selector(self.onLongPressRichView(gestureRecognizer:)), duration: 0.5, target: self)
        // 单击屏幕任意，退出选中状态
        self.view.lu.addTapGestureRecognizer(action: #selector(self.onTapRichView(gestureRecognizer:)), target: self)
        // 根据当前屏幕方向、是否折行，重新布局代码块视图
        self.layoutRichView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            self?.richContainerScrollView.isScrollEnabled = true
            // 取消选中状态、隐藏复制菜单
            self?.richContainerView.richView.switchMode(.normal)
            self?.copyMenuView.isHidden = true
            self?.layoutRichView()
        }, completion: nil)
    }

    // MARK: - 私有方法
    @objc
    private func onTapRichView(gestureRecognizer: UITapGestureRecognizer) {
        self.richContainerScrollView.isScrollEnabled = true
        self.richContainerView.richView.switchMode(.normal)
        self.copyMenuView.isHidden = true
    }

    @objc
    private func onTapCopyMenuView(gestureRecognizer: UITapGestureRecognizer) {
        // 获取copy的字符串
        let resultAttr: NSAttributedString
        if self.richContainerView.richView.isSelectAll() {
            // 不添加message.copy.code.key，详情页复制，粘贴到输入框降级为富文本
            resultAttr = self.viewModel.getAttributeString()
        } else {
            // 这里不会掉用LKCodeElement的getDefaultString，不会添加message.copy.code.key
            resultAttr = self.richContainerView.richView.getCopyString() ?? NSAttributedString(string: "")
        }
        if CopyToPasteboardManager.copyToPasteboardFormAttribute(resultAttr,
                                                                 fileAuthority: .canCopy(false),
                                                                 pasteboardToken: "LARK-PSDA-messenger-codeDetail-longPressMenu-copy-permission",
                                                                 fgService: self.viewModel.userResolver.fg) {
            UDToast.showSuccess(with: BundleI18n.LarkChat.Lark_Legacy_JssdkCopySuccess, on: self.view)
        } else {
            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: self.view)
        }
        // richView.isSelectAll会判断globalStartIndex、globalEndIndex，而switchMode(.normal)会清空
        // 所以需要richView.isSelectAll后再switchMode(.normal)
        self.richContainerView.richView.switchMode(.normal)
        self.copyMenuView.isHidden = true
    }

    @objc
    private func onLongPressRichView(gestureRecognizer: UILongPressGestureRecognizer) {
        // 默认选中所有内容
        self.richContainerView.richView.switchMode(.visual)
        // switchMode不是同步的，所以需要延迟到后续RunLoop执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0168) { [weak self] in
            self?.copyMenuView.isHidden = false
            self?.updateCopyMenuCenter()
        }
    }

    @objc
    private func exit(gestureRecognizer: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }

    @objc
    private func switchLineBreak(gestureRecognizer: UITapGestureRecognizer) {
        self.codeLineBreak = !self.codeLineBreak
        self.switchImage.image = (self.codeLineBreak ? Resources.codeDetailOffWrapIcon : Resources.codeDetailOnWrapIcon).ud.withTintColor(UIColor.ud.iconN1)
        self.richContainerScrollView.isScrollEnabled = true
        // 取消选中状态、隐藏复制菜单
        self.copyMenuView.isHidden = true
        self.richContainerView.richView.switchMode(.normal)
        self.layoutRichView()
    }

    /// 根据当前屏幕方向、是否折行，重新布局代码块视图
    private func layoutRichView() {
        var loadingToast: UDToast?
        var layoutRichViewDidFinish: Bool = false

        // 子线程布局，0.2s后展示出loading
        let viewBoundsSizeWidth = self.view.bounds.size.width
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.2) {
            // 如果0.2s内已经布局完成，则不用展示loading
            guard !layoutRichViewDidFinish else { return }
            // disableUserInteraction设置为true，避免用户短时切换多次，造成卡顿
            loadingToast = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        }
        DispatchQueue.global().async {
            // 代码是否折行
            let contentSize = self.core.layout(CGSize(width: self.codeLineBreak ? viewBoundsSizeWidth - 16 : CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
            // 回到主线程渲染
            DispatchQueue.main.async {
                self.richContainerView.frame = CGRect(origin: .zero, size: contentSize)
                self.richContainerView.richView.frame = CGRect(origin: .zero, size: contentSize)
                self.richContainerScrollView.contentSize = contentSize
                // 自己设置分片大小为半屏，比默认的大，同样会出现空白问题
                // self.richContainerView.richView.maxTiledSize = UInt(contentSize.width * self.richContainerScrollView.frame.height / 2)
                // frame设置后再调用setRichViewCore，setRichViewCore内部会触发LKRichViewAsyncLayer-display的调用，如果LKRichViewAsyncLayer-display调用时frame没值，则会界面空白
                self.richContainerView.richView.setRichViewCore(self.core)
                // 设置布局完成标志，没展示出loading则不用展示
                layoutRichViewDidFinish = true
                loadingToast?.remove()
            }
        }
    }

    /// 根据用户选中的范围，更新菜单视图的中心位置
    private func updateCopyMenuCenter() {
        // 获取所有选中范围
        let selectedRects = self.richContainerView.richView.selectionModule.selectedRects
        // 把选中范围转换为屏幕中的坐标
        let screenRects = selectedRects.map {
            CGRectApplyAffineTransform($0, CGAffineTransform(translationX: -self.richContainerScrollView.contentOffset.x, y: -self.richContainerScrollView.contentOffset.y))
        }
        // 获取选中范围的外围矩形框，就是获取最上、左、下、右的点
        var leftX: CGFloat = CGFloat.greatestFiniteMagnitude
        var rightX: CGFloat = 0
        var topY: CGFloat = CGFloat.greatestFiniteMagnitude
        var bottomY: CGFloat = 0
        screenRects.forEach { rect in
            // 排除异常值
            guard rect.size.width > 0, rect.size.height > 0 else { return }
            // 排除全在上方屏幕外的值
            guard rect.origin.y + rect.size.height >= 0 else { return }
            // 排除全在下方屏幕外的值
            guard rect.origin.y <= self.richContainerScrollView.frame.size.height else { return }

            leftX = min(leftX, rect.origin.x)
            rightX = max(rightX, rect.origin.x + rect.size.width)
            topY = min(topY, rect.origin.y)
            bottomY = max(bottomY, rect.origin.y + rect.size.height)
        }
        let selectedScreenRect = CGRect(origin: CGPoint(x: leftX, y: topY), size: CGSize(width: rightX - leftX, height: bottomY - topY))
        // 先确定菜单项origin.x的位置
        do {
            // 先设置为外围矩形框中心位置
            self.copyMenuView.frame.center.x = selectedScreenRect.origin.x + selectedScreenRect.size.width / 2
            // 修正中心位置，不要超出滚动视图左边
            if self.copyMenuView.frame.center.x - self.copyMenuView.frame.size.width / 2 < 0 {
                self.copyMenuView.frame.center.x = self.copyMenuView.frame.size.width / 2
            }
            // 修正中心位置，不要超出滚动视图右边
            if self.copyMenuView.frame.center.x + self.copyMenuView.frame.size.width / 2 > self.richContainerScrollView.frame.size.width {
                self.copyMenuView.frame.center.x = self.richContainerScrollView.frame.size.width - self.copyMenuView.frame.size.width / 2
            }
        }
        // 再确定菜单项origin.y的位置
        do {
            // 如果选中范围的高度小于菜单项的高度，这时候不能展示在中间，因为要遮挡内容
            if selectedScreenRect.size.height <= self.copyMenuView.frame.size.height {
                // 先判断能不能展示在上面，-8:菜单底/顶和选中范围间隔为8
                if selectedScreenRect.origin.y - self.copyMenuView.frame.size.height - 8 >= 0 {
                    self.copyMenuView.frame.center.y = selectedScreenRect.origin.y - self.copyMenuView.frame.size.height / 2 - 4
                } else {
                    // 否则展示在下面
                    self.copyMenuView.frame.center.y = selectedScreenRect.origin.y + selectedScreenRect.size.height + self.copyMenuView.frame.size.height / 2 + 4
                }
            } else {
                // 展示在中间位置，先设置为外围矩形框中心位置
                self.copyMenuView.frame.center.y = selectedScreenRect.origin.y + selectedScreenRect.size.height / 2
                // 修正中心位置，不要超出滚动视图上边
                if self.copyMenuView.frame.center.y - self.copyMenuView.frame.size.height / 2 < 0 {
                    self.copyMenuView.frame.center.y = self.copyMenuView.frame.size.height / 2
                }
                // 修正中心位置，不要超出滚动视图下边
                if self.copyMenuView.frame.center.y + self.copyMenuView.frame.size.height / 2 > self.richContainerScrollView.frame.size.height {
                    self.copyMenuView.frame.center.y = self.richContainerScrollView.frame.size.height - self.copyMenuView.frame.size.height / 2
                }
            }
        }
        // copyMenuView是加到self.view上的，然而上面的逻辑是计算相对于richContainerScrollView的位置，所以这里要加上richContainerScrollView.origin以映射到self.view上
        self.copyMenuView.frame = CGRectApplyAffineTransform(
            self.copyMenuView.frame,
            CGAffineTransform(translationX: self.richContainerScrollView.frame.origin.x, y: self.richContainerScrollView.frame.origin.y)
        )
    }

    /// 当前所有的selectedRects已经全部在屏幕外
    private func currSelectedRectsIsAllOverScreen() -> Bool {
        var currSelectedRectsIsAllOverScreen = true
        // 获取所有选中范围
        let selectedRects = self.richContainerView.richView.selectionModule.selectedRects
        selectedRects.forEach { rect in
            // 判断该rect是否在用户屏幕上，rect.origin - scrollView.contentOffset = 在屏幕上的位置
            let screenRect = CGRectApplyAffineTransform(rect, CGAffineTransform(translationX: -self.richContainerScrollView.contentOffset.x, y: -self.richContainerScrollView.contentOffset.y))
            // 判断和bounds是否有交集，如果有交集，说明在屏幕内；不能使用bounds来判断，bounds.origin.y = contentOffset.y，导致都有交集，我也觉得有点神奇
            if screenRect.intersects(CGRect(origin: .zero, size: self.richContainerScrollView.bounds.size)) {
                currSelectedRectsIsAllOverScreen = false
                return
            }
        }
        return currSelectedRectsIsAllOverScreen
    }

    // MARK: - LKRichViewSelectionDelegate
    /// 拖动光标时，隐藏菜单、禁止UIScrollView视图滚动（手势冲突）
    func willDragCursor(_ view: LKRichView) {
        self.richContainerScrollView.isScrollEnabled = false
        self.copyMenuView.isHidden = true
    }
    func didDragCursor(_ view: LKRichView) {
        self.richContainerScrollView.isScrollEnabled = true
        self.copyMenuView.isHidden = false
        self.updateCopyMenuCenter()
    }
    func handleCopyByCommand(_ view: LKRichView, text: NSAttributedString?) {}

    // MARK: - UIScrollViewDelegate
    /// UIScrollView滚动时，隐藏菜单
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.copyMenuView.isHidden = true
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 当前处于选中状态，才展示菜单
        if !decelerate, self.richContainerView.richView.selectionModule.getMode() == .visual {
            // 如果选中范围已经全部在屏幕外，则取消选中态
            if self.currSelectedRectsIsAllOverScreen() {
                self.richContainerView.richView.switchMode(.normal)
                return
            }
            self.copyMenuView.isHidden = false
            self.updateCopyMenuCenter()
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 当前处于选中状态，才展示菜单
        if self.richContainerView.richView.selectionModule.getMode() == .visual {
            // 如果选中范围已经全部在屏幕外，则取消选中态
            if self.currSelectedRectsIsAllOverScreen() {
                self.richContainerView.richView.switchMode(.normal)
                return
            }
            self.copyMenuView.isHidden = false
            self.updateCopyMenuCenter()
        }
    }
}

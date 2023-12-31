//
//  FeedContentView.swift
//  SKCommon
//
//  Created by huayufan on 2021/5/20.
//  


import SKUIKit
import SnapKit
import SKResource
import RxSwift
import RxCocoa
import Lottie
import UniverseDesignToast

class FeedContentView: UIView {
        
    enum MenuAction {
        case copy
        case translate
        case showOriginal
        
        var title: String {
            switch self {
            case .copy:
                return BundleI18n.SKResource.Doc_Doc_Copy
            case .translate:
                return BundleI18n.SKResource.Doc_More_Translate
            case .showOriginal:
                return BundleI18n.SKResource.Doc_Translate_ViewOriginal
            }
        }
        
        var selector: Selector {
            switch self {
            case .copy:
                return #selector(FeedContentView.copyText)
            case .translate:
                return #selector(FeedContentView.translateText)
            case .showOriginal:
                return #selector(FeedContentView.showOriginalText)
            }
        }
    }
    
    enum Mode {
        case normal(config: FeedMessageContent)
        case hilighted(config: FeedMessageContent)
    }
    
    enum TranslateStatus {
        case play
        case stop
    }
    
    enum Event {
        case copy
        case translate
        case showOriginal
        /// 点击评论内容, 因为需要定位到点击的是否是URL，需要传Label和手势出去
        case tap(UILabel, UITapGestureRecognizer)
    }
    
    struct Layout {
        static var iconSize = CGSize(width: 40, height: 40)
    }
    
    class TranslatedView: UIView {
        
        struct Layout {
            static var iconSize = CGSize(width: 16, height: 16)
        }
        private lazy var translatedIconView: LOTAnimationView = {
            return AnimationViews.commentTranslting ?? LOTAnimationView()
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(translatedIconView)
            translatedIconView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.size.equalTo(Layout.iconSize)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func play() {
            translatedIconView.play()
        }
        
        func stop() {
            translatedIconView.stop()
        }
    }
    
    var bgView = UIView()
    
    var textLabel = UILabel()
    
    var mode: Mode?
    
    var actions = PublishRelay<Event>()
    
    var translatedIcon: TranslatedView?
    
    /// 加载有点耗时 需要懒加载处理
    var realTranslatedIcon: TranslatedView {
        if translatedIcon == nil {
            translatedIcon = TranslatedView()
            self.addSubview(translatedIcon!)
            self.realTranslatedIcon.snp.makeConstraints { (make) in
                make.size.equalTo(Layout.iconSize)
                let padding = (Layout.iconSize.height - TranslatedView.Layout.iconSize.height) / 2.0
                make.right.equalToSuperview().offset(padding)
                make.bottom.equalTo(textLabel.snp.bottom).offset(padding)
            }
            translatedIcon?.isUserInteractionEnabled = true
            translatedIcon?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(translatedIconClick)))
        }
        return translatedIcon!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
        addGesture()
    }
    
    private func setupInit() {
        bgView.construct {
            $0.backgroundColor = UIColor.ud.N200
            $0.layer.cornerRadius = 4
            $0.layer.masksToBounds = true
        }
        
        textLabel.construct {
            $0.textColor = UIColor.ud.N900
            $0.font = UIFont.systemFont(ofSize: 16)
            $0.numberOfLines = 0
            $0.isUserInteractionEnabled = true
        }
        addSubview(bgView)
        addSubview(textLabel)
    }
    
    private func setupLayout() {
        bgView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(textLabel).inset(-2)
            make.left.right.equalTo(textLabel).inset(-4)
        }
        
        textLabel.snp.makeConstraints { (make) in
            make.top.bottom.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc
    func translatedIconClick() {
        actions.accept(.showOriginal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - menu

extension FeedContentView {
    
    private func addGesture() {
        let pressGesture = UILongPressGestureRecognizer(target: self, action: #selector(pressAction(gesture:)))
        addGestureRecognizer(pressGesture)
        
        let tapGestur = UITapGestureRecognizer(target: self, action: #selector(tapAction(gesture:)))
        textLabel.addGestureRecognizer(tapGestur)
    }
    
    @objc
    func pressAction(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let mode = self.mode else { return }
            self.becomeFirstResponder()
            let menuVC = UIMenuController.shared
            switch mode {
            case let .normal(config),
                 let .hilighted(config):
                let availableActions = config.actions.map { UIMenuItem(title: $0.title, action: $0.selector) }
                if availableActions.isEmpty {
                    
                    // 弹Toast提醒用户无可用操作
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_Perms_CommentRestricted_toast_mob, on: self.window ?? self)
                    
                    return
                }
                menuVC.menuItems = availableActions
            }
            if menuVC.isMenuVisible { return }
            menuVC.setTargetRect(self.textLabel.bounds, in: self)
            menuVC.setMenuVisible(true, animated: true)
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copyText) ||
            action == #selector(translateText) ||
            action == #selector(showOriginalText) {
            return true
        } else {
            // 隐藏系统自带的菜单项
            return false
        }
    }
    
    @objc
    func tapAction(gesture: UITapGestureRecognizer) {
        actions.accept(.tap(textLabel, gesture))
    }
    
    @objc
    func copyText() {
        actions.accept(.copy)
    }
    
    @objc
    func translateText() {
        updateTranslate(status: .play)
        actions.accept(.translate)
    }
    
    @objc
    func showOriginalText() {
        actions.accept(.showOriginal)
    }
    
    private func updateTranslate(status: TranslateStatus?) {
        guard let st = status else {
            translatedIcon?.isHidden = true
            return
        }
        switch st {
        case .stop:
            realTranslatedIcon.stop()
        case .play:
            realTranslatedIcon.play()
        }
        realTranslatedIcon.isHidden = false
        updateIconConstraints()
    }
    
    /// 若翻译文字最后一行有空位，将翻译按钮放在翻译文字范围右下角内
    /// 否则在放在翻译文字范围外右下角底部，分开显示
    func updateIconConstraints() {
        setNeedsLayout()
        layoutIfNeeded()
        let lastPadding = self.bounds.width - textLabel.lastLineMaxX(width: self.bounds.width) - 4
        let isEnough = lastPadding > Layout.iconSize.width
        realTranslatedIcon.snp.updateConstraints { (make) in
            let padding = (Layout.iconSize.height - TranslatedView.Layout.iconSize.height) / 2.0
            let bottomPadding = padding + TranslatedView.Layout.iconSize.height
            make.bottom.equalTo(textLabel.snp.bottom)
                       .offset(isEnough ? padding : bottomPadding)
        }
    }
    
    // realTranslatedIcon可能超出父视图，需要响应点击事件
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == nil, let iconView = translatedIcon {
            let convertPoint = iconView.convert(point, from: self)
            if iconView.bounds.contains(convertPoint) {
                return iconView
            }
        }
        return view
    }
}


// MARK: - public

extension FeedContentView {
    
    func update(mode: Mode) {
        self.mode = mode
        switch mode {
        case let .normal(config):
            textLabel.attributedText = config.text
            bgView.isHidden = true
            updateTranslate(status: config.translateStatus)
            updateMenuItem()
        case let .hilighted(config):
            textLabel.attributedText = config.text
            bgView.isHidden = config.text == nil
            updateTranslate(status: config.translateStatus)
            updateMenuItem()
        }
    }
}

extension FeedContentView {
    
    func updateMenuItem() {
        let menuVC = UIMenuController.shared
        menuVC.setMenuVisible(false, animated: true)
    }
}

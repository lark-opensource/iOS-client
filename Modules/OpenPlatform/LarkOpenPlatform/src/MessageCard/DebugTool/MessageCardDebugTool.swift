//
//  MessageCardDebugTool.swift
//  OpenPlatForm
//
//  Created by zhangjie.alonso on 2022/8/10.
//
#if BETA || ALPHA || DEBUG
import Foundation
import RxSwift
import LarkModel
import EENavigator
import UIKit
import RxCocoa
import RustPB
import SnapKit
import LarkEMM
import UniverseDesignButton
import RoundedHUD
import OPFoundation

final class MessageCardDebugEditController: UIViewController {

    /// 刷新卡片
    private let debugHandler: ((CardContent) -> Void)?
    private var content: CardContent
    private var message: Message
    /// 判断键盘是否存在
    private var keyBoardShow: Bool = false
    private let disposeBag = DisposeBag()
    private let ButtonHeight: CGFloat = 48
    private let ButtonMargin: CGFloat = 16
    /// 内容视图
    private lazy var contentView: UIView = UIView()
    private let containerView = UIView()
    private let messageIDLabel :UILabel = {
        let label = UILabel()
        label.text = "MessageID: "
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    private lazy var messageVersionLabel :UILabel = {
        let label = UILabel()
        label.text = "Version: O(\( self.message.contentVersion))"
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    private var isNewCard: Bool
    
    /// 富文本预览编辑
    private lazy var richTextTextView: UITextView = {
        var richTextTextView = UITextView()
        if isNewCard {
            richTextTextView.text = content.jsonBody
        } else {
            do {
                richTextTextView.text = try content.richText.jsonString()
            }catch {
                showFailView(failInfo: "decode failed: \(error)")
            }
        }

        richTextTextView.font = .systemFont(ofSize: 15)
        richTextTextView.backgroundColor = UIColor.ud.N200
        richTextTextView.isEditable = true
        richTextTextView.isSelectable = true
        richTextTextView.textContainer.lineFragmentPadding = 0
        richTextTextView.textContainerInset = .zero
        return richTextTextView
    }()

    private lazy var messageIDTextView: UITextView = {
        var messageIDTextView = UITextView()
        messageIDTextView.text = message.id
        messageIDTextView.font = .systemFont(ofSize: 15)
        messageIDTextView.backgroundColor = UIColor.clear
        messageIDTextView.isEditable = false
        messageIDTextView.isSelectable = true
        messageIDTextView.textContainer.lineFragmentPadding = 0
        messageIDTextView.textContainerInset = .zero
        return messageIDTextView
    }()
    /// 预览按钮
    private lazy var previewButton: UIButton = self.makeButton(name: "Preview")
    /// 清空按钮
    private lazy var clearButton: UIButton = self.makeButton(name: "Clear")
    /// 获取message内容按钮
    private lazy var messageButton: UIButton = self.makeButton(name: "Content")

    public init(content: CardContent,
                handler: ((CardContent) -> Void)? = nil,
                message: Message,
                isNewCard: Bool = false) {
        self.debugHandler = handler
        self.content = content
        self.message = message
        self.isNewCard = isNewCard
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChange(notification:)), name: Self.keyboardWillChangeFrameNotification, object: nil)
        let pasteboardConfig = PasteboardConfig(token: OPSensitivityEntryToken.debug.psdaToken)
        SCPasteboard.general(pasteboardConfig).string = richTextTextView.text
        self.showToast(info: "data saved to pasteboard")
        buildBackgroundView()
        /// 布局子视图
        doLayoutSubViews()
        /// 注册事件
        registerEvent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    /// 点击蒙层的dismiss操作
    @objc
    func dismiss(_ gesture: UIGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    func buildBackgroundView() {
        let exitGesture = UITapGestureRecognizer(target: self, action: #selector(cancelPage))
        let backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView)
        backgroundView.addGestureRecognizer(exitGesture)
        let safeAreaMaskBG = UIView()
        safeAreaMaskBG.backgroundColor = UIColor.ud.bgFloat
        view.addSubview(safeAreaMaskBG)
        safeAreaMaskBG.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            $0.bottom.equalToSuperview()
        }
    }

    func makeButton(name: String) -> UDButton {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.ud.colorfulBlue,
                                                      textColor: UIColor.ud.primaryOnPrimaryFill)
        var config = UDButtonUIConifg(normalColor: normalColor)
        config.disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                          backgroundColor: UIColor.ud.fillDisabled,
                                                          textColor: UIColor.ud.udtokenBtnPriTextDisabled)
        config.radiusStyle = .square
        config.type = .big
        let button = UDButton(config)
        button.setTitle(name, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        button.layer.masksToBounds = true
        button.isEnabled = true
        return button
    }

    /// 布局子视图
    private func doLayoutSubViews() {
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.roundCorners(corners: [.topLeft, .topRight], radius: 16.0)

        view.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().priority(800)
            $0.top.equalToSuperview().offset(30)
        }

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.right.left.top.bottom.equalToSuperview()
        }

        containerView.addSubview(richTextTextView)
        containerView.addSubview(messageIDTextView)
        containerView.addSubview(messageIDLabel)
        containerView.addSubview(messageVersionLabel)
        
        var btnView = UIView()
        containerView.addSubview(btnView)
        btnView.addSubview(clearButton)
        btnView.addSubview(messageButton)
        btnView.addSubview(previewButton)

        richTextTextView.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(messageIDTextView.snp.top).offset(-10)
        }

        messageIDLabel.snp.makeConstraints { make in
            make.left.equalTo(richTextTextView)
            make.width.equalTo(100)
            make.height.equalTo(15)
            make.bottom.equalTo(messageVersionLabel.snp.top).offset(-10)
        }

        messageIDTextView.snp.makeConstraints { make in
            make.right.equalTo(richTextTextView)
            make.left.equalTo(messageIDLabel.snp.right)
            make.bottom.equalTo(messageIDLabel.snp.bottom)
            make.top.equalTo(messageIDLabel.snp.top)
        }
        messageVersionLabel.snp.makeConstraints { make in
            make.top.equalTo(messageIDLabel.snp.bottom)
            make.height.equalTo(15)
            make.left.equalTo(richTextTextView)
            make.bottom.equalTo(btnView.snp.top).offset(-10)
        }
        
        btnView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-30)
            make.height.equalTo(ButtonHeight)
        }
        
        previewButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalTo(clearButton.snp.left).offset(-10)
            make.bottom.top.equalToSuperview()
        }

        clearButton.snp.makeConstraints { (make) in
            make.left.equalTo(previewButton.snp.right)
            make.right.equalTo(messageButton.snp.left).offset(-10)
            make.bottom.top.equalToSuperview()
            make.width.equalTo(previewButton)
        }

        messageButton.snp.makeConstraints { make in
            make.left.equalTo(clearButton.snp.right)
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(previewButton)
        }
        
        var bottomView: UIView = UIView()
        bottomView.backgroundColor = .ud.bgBody
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(contentView.snp.bottom)
        }
    }

    func showFailView(failInfo: String) {
        let alertController = UIAlertController(title: "Fail", message: failInfo, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] _ in
            alertController?.dismiss(animated: true)
        })
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
}

extension MessageCardDebugEditController {
    @objc
    func keyboardChange(notification: Notification) {
        guard let kbFrame = notification.userInfo?[Self.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let duration = notification.userInfo?[Self.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        UIView.animate(withDuration: duration) { [self] in
            let originBottom = self.view.safeAreaLayoutGuide.layoutFrame.maxY + self.additionalSafeAreaInsets.bottom
            let kbFrame = self.view.convert(kbFrame, from: nil)
            self.additionalSafeAreaInsets.bottom = max(originBottom - kbFrame.minY, 0)
            self.view.layoutIfNeeded()
        }
    }

    @objc
    private func cancelPage() {
        dismiss(animated: true, completion: nil)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        let pasteboardConfig = PasteboardConfig(token: OPSensitivityEntryToken.debug.psdaToken)
        SCPasteboard.general(pasteboardConfig).string = richTextTextView.text
        self.showToast(info: "data saved to pasteboard")
        super.touchesBegan(touches, with: event)
    }

    // 注册事件
    private func registerEvent() {
        previewButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                var newRichTextJson = self.richTextTextView.text ?? ""
                    do {
                        if self.isNewCard {
                            self.content.jsonBody = newRichTextJson
                        } else {
                            var richText = try RustPB.Basic_V1_RichText(jsonString: newRichTextJson)
                            self.content.richText = richText
                        }
                        self.debugHandler?(self.content)
                        self.dismiss(animated: true)
                    } catch {
                        self.showFailView(failInfo: "json decode failed: \(error)")
                    }
            })
            .disposed(by: disposeBag)
        
        clearButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.richTextTextView.text = ""
            })
            .disposed(by: disposeBag)
        
        messageButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let pasteboardConfig = PasteboardConfig(token: OPSensitivityEntryToken.debug.psdaToken)
                SCPasteboard.general(pasteboardConfig).string = "[content: ]\(self.message.content as? CardContent)\n [translateContent]:\(self.message.translateContent as? CardContent)"
                self.showToast(info: "Message saved to pasteboard")
            })
            .disposed(by: disposeBag)
    }
    
    private func showToast(info: String) {
        DispatchQueue.main.async {
            guard let currentVC = Navigator.shared.mainSceneWindow?.fromViewController,
                  let targetView = currentVC.view else {
                return
            }
            RoundedHUD().showTips(with: info, on: targetView)
        }
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}
#endif

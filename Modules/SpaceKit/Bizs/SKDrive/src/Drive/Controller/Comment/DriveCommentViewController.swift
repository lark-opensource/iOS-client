//
// DriveCommentViewController.swift
//  SpaceKit
//
//  Created by zenghao on 2019/5/14.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import SpaceInterface
import SKInfra
import UniverseDesignColor

class DriveCommentViewController: OverCurrentContextViewController {
    private let dependency: DriveAtInputTextViewDependency
    private let atInputTextView: AtInputViewType?
    private let atInputMaskView = UIView()
    private let atInputBottomPlaceHolderView = UIView()

    var commentSendCompletion: ((RNCommentData, DriveAreaComment.Area) -> Void)?
    var commentVCWillDismiss: (() -> Void)?
    var showAreaEditView: ((Bool) -> Void)?

    var fakeCommentID: String {
        return DocsTracker.encrypt(id: dependency.fileToken + dependency.dataVersion)
    }

    init(dependency: DriveAtInputTextViewDependency) {
        self.dependency = dependency
        let params = AtInputViewInitParams(dependency: dependency,
                                           font: UIFont.systemFont(ofSize: 16),
                                           ignoreRotation: false)
        self.atInputTextView = DocsContainer.shared.resolve(AtInputViewType.self, argument: params)
        self.atInputTextView?.forceVoiceButtonHidden(isHidden: false)
        super.init(nibName: nil, bundle: nil)
        /// 恢复上一次的评论内容
        restoreComment()
        dependency.commentSendCompletion = { [weak self] (commentData) -> Void in
            guard let self = self else { return }
            let area = self.dependency.area
            self.dismiss(animated: false, completion: { [weak self] in
                self?.commentSendCompletion?(commentData,
                                            area)
            })
        }
        dependency.areaBoxClicked = { [weak self] sender in
            guard let self = self else { return }
            if sender.isSelected {
                self.dependency.area = DriveAreaComment.Area.blankArea
                self.showAreaEditView?(false)
            } else {
                self.dismiss(animated: true, completion: nil)
                self.showAreaEditView?(true)
            }
            sender.isSelected = !sender.isSelected
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.driveInfo("DriveCommentViewController -- deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc
    func tapCommentMaskView() {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
        commentVCWillDismiss?()
    }

    @objc
    func keyboardWillShow(_ notification: NSNotification) {
        let textViewIsFirstResponder = atInputTextView?.textViewIsFirstResponder() ?? false
        guard let endFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let time = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            textViewIsFirstResponder else {
                DocsLogger.warning("no need to handle Keyboard will show notification")
                return
        }
        guard let currentWindowHeight = view.window?.frame.height else {
            DocsLogger.error("failed to get current window when keyboard show")
            return
        }
        let commentFrameInWindow = view.convert(view.frame, to: nil)
        let bottomExtraOffset = currentWindowHeight - commentFrameInWindow.maxY
        let bottomOffset = endFrame.size.height - bottomExtraOffset
        let actualOffset = max(0, bottomOffset)
        UIView.animate(withDuration: time) {
            self.atInputTextView?.snp.updateConstraints({ (make) in
                make.bottom.equalToSuperview().inset(actualOffset)
            })
            self.view.layoutIfNeeded()
        }
    }

    @objc
    func keyboardWillHide(_ notification: NSNotification) {
        guard let time = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            DocsLogger.warning("no need to handle Keyboard will hide notification")
            return
        }

        UIView.animate(withDuration: time, animations: {
            self.atInputTextView?.snp.updateConstraints({ (make) in
                make.bottom.equalToSuperview().inset(self.view.safeAreaInsets.bottom)
            })
            self.view.layoutIfNeeded()
        })
    }

    /// 重置评论内容
    private func restoreComment() {
        // 新逻辑
        if let draftScene = dependency.commentDraftScene {
            let draftKey = CommentDraftKey(entityId: dependency.docsInfo?.token,
                                           sceneType: draftScene)
            guard let manager = DocsContainer.shared.resolve(CommentDraftManagerInterface.self) else {
                DocsLogger.error("resolve draft manager error", component: LogComponents.comment)
                return
            }
            let draftResult: Swift.Result<CommentDraftModel, Error> = manager.commentModel(for: draftKey)
            if case .success(let model) = draftResult {
                guard let parser = DocsContainer.shared.resolve(AtInfoXMLParserInterface.self) else {
                    return
                }
                let attrText = parser.decodedAttrString(model: model, attributes: AtInfo.TextFormat.defaultAttributes(), token:  dependency.docsInfo?.token ?? "", type: dependency.docsInfo?.type, checkPermission: false)
                let imageInfos = model.imageList.map { $0.lagacyModel() }
                atInputTextView?.update(imageList: imageInfos, attrText: attrText)
            }
        }
    }
}

private extension DriveCommentViewController {
    func initUI() {
        setupMaskView()

        if let textView = atInputTextView {
            view.addSubview(textView)
            textView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(self.view.safeAreaInsets.bottom)
                make.height.greaterThanOrEqualTo(80)
            }
            textView.textviewBecomeFirstResponder()

            atInputBottomPlaceHolderView.backgroundColor = UDColor.bgBody
            view.addSubview(atInputBottomPlaceHolderView)
            atInputBottomPlaceHolderView.snp.makeConstraints { make in
                make.top.equalTo(textView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        } else {
            spaceAssertionFailure("drive comment textView is nil")
        }
    }

    func setupMaskView() {
        atInputMaskView.backgroundColor = UIColor.clear.withAlphaComponent(0.01)
        view.addSubview(atInputMaskView)

        atInputMaskView.snp.makeConstraints({ (make) in
            make.top.left.right.bottom.equalToSuperview()
        })
        let ges = UITapGestureRecognizer(target: self, action: #selector(tapCommentMaskView))
        atInputMaskView.addGestureRecognizer(ges)
    }
}

extension DriveCommentViewController: ClipboardProtectProtocol {
    func getDocumentToken() -> String? {
        let token = dependency.fileToken
        return token.isEmpty ? nil : token
    }
}

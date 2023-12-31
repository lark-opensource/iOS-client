//
//  EventNotesViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/3/23.
//

import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import CalendarFoundation
import LarkContainer
import UniverseDesignFont
import UniverseDesignToast
// 日程 - 编辑描述页

protocol EventNotesViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventNotesViewController)
    func didFinishEdit(from viewController: EventNotesViewController)
}

final class EventNotesViewController: UIViewController, EventEditConfirmAlertSupport, UserResolverWrapper {

    @ScopedInjectedLazy var docsDispatherSerivce: DocsDispatherSerivce?
    let userResolver: UserResolver
    weak var delegate: EventNotesViewControllerDelegate?
    internal private(set) var notes: EventNotes

    private let disposeBag = DisposeBag()
    private var disableKeyboard = true
    private lazy var docsViewHolder: DocsViewHolder? = {
        return docsDispatherSerivce?.sell()
    }()
    init(notes: EventNotes, userResolver: UserResolver) {
        self.notes = notes
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        /// 设置自定义处理url，防止内嵌网页直接跳转
        docsViewHolder?.customHandle = { _, _ in }
        docsViewHolder?.disableBecomeFirstResponder = { [weak self] in
            return self?.disableKeyboard ?? true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_Edit_DescriptionTitle
        view.backgroundColor = UIColor.ud.bgBody
        setupNaviItem()
        setupDocsView()
        navigationController?.presentationController?.delegate = self
    }

    private func setupNaviItem() {
        let cancelItem = LKBarButtonItem(
            title: BundleI18n.Calendar.Calendar_Common_Cancel
        )
        cancelItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.docsViewHolder?.isNotChanged { (notChanged, error) in
                    if let error = error {
                        self.logError(error, withMessage: "check changed failed")
                        self.delegate?.didCancelEdit(from: self)
                        return
                    }
                    if let notChanged = notChanged, !notChanged {
                        self.showAlert()
                        return
                    }
                    self.delegate?.didCancelEdit(from: self)
                }
            }
            .disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = cancelItem

        let doneItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Done, fontStyle: .medium)
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.handleDone()
            }
            .disposed(by: disposeBag)
        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        navigationItem.rightBarButtonItem = doneItem
    }

    private func setupDocsView() {
        guard let docsView = docsViewHolder?.getDocsView(false, shouldJumpToWebPage: true) else { return }
        docsView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(docsView)
        docsView.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }
        docsView.invalidateIntrinsicContentSize()
        docsView.layoutIfNeeded()

        let setData = { [weak self] in
            guard let self = self else { return }
            let success = { [weak self] in
                self?.disableKeyboard = false
                self?.docsViewHolder?.becomeFirstResponder()
            }
            switch self.notes {
            case .html(let text), .plain(let text):
                self.docsViewHolder?.setDoc(
                    html: text,
                    displayWidth: self.view.frame.width - 32,
                    success: success,
                    fail: { [weak self] error in
                        self?.logError(error, withMessage: "set html failed")
                    }
                )
            case .docs(let data, let text):
                self.docsViewHolder?.setDoc(
                    data: data.isEmpty ? text : data,
                    displayWidth: self.view.frame.width - 32,
                    success: success,
                    fail: { [weak self] error in
                        self?.logError(error, withMessage: "set data failed")
                    }
                )
            }
        }
        if #available(iOS 13.0, *) {
            Observable<Int>.interval(.milliseconds(2000), scheduler: MainScheduler.instance)
                .bind { [weak self] _ in
                    guard let self = self else { return }
                    self.docsViewHolder?.isNotChanged { (notChanged, _) in
                        if let notChanged = notChanged {
                            self.isModalInPresentation = !notChanged
                        }
                    }
                }.disposed(by: disposeBag)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.docsViewHolder?.setEditable(
                true,
                success: { [weak self] in
                    self?.docsViewHolder?.set(
                        placeHolder: BundleI18n.Calendar.Calendar_Edit_InputDescription,
                        success: { [weak self] in
                            self?.logInfo("set docs placeholder succeed")
                            var style = DocsEditStyle()
                            style.innerHeight = "\(docsView.bounds.height)"
                            style.isSysBold = UDFontAppearance.isBoldTextEnabled
                            self?.docsViewHolder?.setStyle(
                                style,
                                success: { [weak self] in
                                    self?.logInfo("set style succeed")
                                    setData()
                                },
                                fail: { [weak self] (error) in
                                    self?.logError(error, withMessage: "set style failed")
                                }
                            )
                        },
                        fail: { [weak self] (error) in
                            self?.logError(error, withMessage: "set docs placeholder failed")
                        }
                    )
                    self?.logInfo("set isEditable succeed")
                },
                fail: { [weak self] error in
                    self?.logError(error, withMessage: "set isEditable failed")
                }
            )
        }

        docsViewHolder?.onPasteDocsCallBack = { [weak self] accessInfos in
            guard let self = self else { return }
            if accessInfos.allSatisfy { $0 } {
                UDToast.showTips(with: I18n.Calendar_Bot_EventParticipantGrantView, on: self.view)
            } else if accessInfos.allSatisfy { !$0 } {
                return
            } else {
                UDToast.showTips(with: I18n.Calendar_Bot_EventParticipantGrantViewExcept, on: self.view)
            }
        }
    }

    private func handleDone() {
        let notesGetter: (@escaping (EventNotes) -> Void) -> Void
        switch notes {
        case .html: notesGetter = getHtmlNotes
        case .plain: notesGetter = getPlainNotes
        case .docs: notesGetter = getDocsNotes
        }
        notesGetter { [weak self] notes in
            guard let self = self else { return }
            self.notes = notes
            self.delegate?.didFinishEdit(from: self)
        }
    }

    private func getHtmlNotes(withCompletion completion: @escaping (EventNotes) -> Void) {
        docsViewHolder?.getDocHtml { [weak self] (text, error) in
            if let error = error {
                self?.logError(error, withMessage: "getHtmlNotes failed")
                completion(.html(text: ""))
                return
            }
            self?.logInfo("get htmlText succeed")
            let text = (text ?? "").trimmingCharacters(in: .whitespaces)
            completion(.html(text: text))
        }
    }

    private func getPlainNotes(withCompletion completion: @escaping (EventNotes) -> Void) {
        docsViewHolder?.getPainText { [weak self] (text, error) in
            if let error = error {
                self?.logError(error, withMessage: "getPlainNotes failed")
                completion(.plain(text: ""))
                return
            }
            self?.logInfo("get plainText succeed")
            let text = (text ?? "").trimmingCharacters(in: .whitespaces)
            completion(.plain(text: text))
        }
    }

    private func getDocsNotes(withCompletion completion: @escaping (EventNotes) -> Void) {
        docsViewHolder?.getPainText { [weak self] (plainText, error) in
            if let error = error {
                self?.logError(error, withMessage: "getPainText failed")
                completion(.docs(data: "", plainText: ""))
                return
            }
            self?.logInfo("get plainText succeed")
            self?.docsViewHolder?.getDocData { [weak self] (data, error) in
                if let error = error {
                    self?.logError(error, withMessage: "getDocData failed")
                    completion(.docs(data: "", plainText: ""))
                    return
                }
                guard let data = data,
                    let plainText = plainText?.trimmingCharacters(in: .whitespacesAndNewlines),
                    !plainText.isEmpty,
                    !data.isEmpty else {
                    completion(.docs(data: "", plainText: ""))
                    return
                }
                self?.logInfo("get docData succeed")
                completion(.docs(data: data, plainText: plainText))
            }
        }
    }

    private func showAlert() {
        let alertTexts = EventEditConfirmAlertTexts(
            message: BundleI18n.Calendar.Calendar_Alert_UnsavedDesAlert
        )
        self.showConfirmAlertController(
            texts: alertTexts,
            confirmHandler: { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEdit(from: self)
            }
        )
    }

    private func logInfo(_ message: String) {
        operationLog(message: message, optType: "set notes")
        docsViewHolder?.logger().info(message)
    }

    private func logError(_ error: Error, withMessage message: String) {
        normalErrorLog(message)
        assertionFailure()
        docsViewHolder?.logger().error(message, error: error)
    }
}

extension EventNotesViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        self.showAlert()
    }
}

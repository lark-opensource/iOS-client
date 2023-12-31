//
//  MinutesAddCommentsViewController.swift
//  Minutes
//
//  Created by yangyao on 2021/1/29.
//

import UIKit
import MinutesFoundation
import UniverseDesignToast
import MinutesNetwork

struct AddCommentsVCParams {
    static let isNewComment = "isNewComment"
    static let pid = "pid"
    static let quote = "quote"
    static let offsetAndSize = "offsetAndSize"
    static let fillText = "fillText"
    static let selectedRange = "selectedRange"
}

typealias OffsetAndSize = (String, NSInteger, NSInteger, Int)

class MinutesAddCommentsViewController: UIViewController {
    lazy var addCommentsView: MinutesAddCommentsView = {
        let view = MinutesAddCommentsView()
        view.sendCommentsBlock = { [weak self, weak view] text in
            guard let self = self, let commentsView = view else { return }
            commentsView.showLoading(true)

            if self.isNewComment {
                self.commentsViewModel?.sendCommentsAction(catchError: true, false, text: text, pid: self.pid, quote: self.quote, offsetAndSize: self.offsetAndSize, success: { response in
                    commentsView.showLoading(false)
                    self.commentSuccessBlock?(response)
                }, fail: { (_) in
                    commentsView.showLoading(false)
                })
            } else {
                self.sendCommentsBlock?(text)
            }
        }
        return view
    }()

    var sendCommentsBlock: ((String) -> Void)?
    var commentSuccessBlock: ((CommonCommentResponse) -> Void)?
    var dismissSelfBlock: ((String) -> Void)?

    let commentsViewModel: MinutesCommentsViewModel?
    let isNewComment: Bool
    let pid: String
    let quote: String
    let offsetAndSize: [OffsetAndSize]

    let fillText: String?
    let selectedRange: NSRange?
    let height: CGFloat = 132

    init(commentsViewModel: MinutesCommentsViewModel?, info: [String: Any]) {
        self.commentsViewModel = commentsViewModel

        self.isNewComment = info[AddCommentsVCParams.isNewComment] as? Bool ?? false
        self.pid = info[AddCommentsVCParams.pid] as? String ?? ""
        self.quote = info[AddCommentsVCParams.quote] as? String ?? ""
        self.offsetAndSize = info[AddCommentsVCParams.offsetAndSize] as? [OffsetAndSize] ?? []
        self.fillText = info[AddCommentsVCParams.fillText] as? String
        self.selectedRange = info[AddCommentsVCParams.selectedRange] as? NSRange

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let containerView = UIView()
        view.addSubview(containerView)
        containerView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(dismissSelf))
        containerView.addGestureRecognizer(tapGesture)
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
        view.addSubview(addCommentsView)
        addCommentsView.frame = CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height)

        addCommentsView.quoteString = quote
        addCommentsView.textView.text = fillText
        addKeyboardObserve()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addCommentsView.textView.becomeFirstResponder()
    }

    @objc func dismissSelf() {
        dismissSelfBlock?(addCommentsView.textContent)
        dismiss(animated: false, completion: nil)
    }

    func addKeyboardObserve() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardEvent(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardEvent(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc func handleKeyboardEvent(notification: Notification) {
        if notification.name == UIResponder.keyboardWillChangeFrameNotification {
            let userInfo = notification.userInfo
            let frame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
            let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.0
            let curveValue = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0

            UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curveValue), animations: {
                self.addCommentsView.frame = CGRect(x: 0, y: self.view.bounds.height - frame.height - self.height, width: self.view.bounds.width, height: self.height)
                self.view.layoutIfNeeded()
            })
        } else if notification.name == UIResponder.keyboardWillHideNotification {
            self.addCommentsView.frame = CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height)
            self.view.layoutIfNeeded()
        }
    }
}

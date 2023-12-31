//
// Created by duanxiaochen.7 on 2020/10/23.
// Affiliated with SpaceKit.
//
// Description:

import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor

class ReminderTextView: UIView, UITextViewDelegate {

    weak var delegate: ReminderTextViewDelegate?
    private var isPlaceHolderOpportunity: Bool = true

    lazy var label = UILabel().construct { it in
        it.font = .systemFont(ofSize: 16)
    }

    lazy var textView = SKBaseTextView().construct { it in
        it.isScrollEnabled = false
        it.isUserInteractionEnabled = true
        it.delegate = self
        it.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        it.font = UIFont.systemFont(ofSize: 17)
        it.textContainer.lineFragmentPadding = 0
        it.layer.borderWidth = 1
        it.layer.cornerRadius = 4
        it.layer.ud.setBorderColor(UDColor.N400)
    }

    init(title: String, text: String?, delegate: ReminderTextViewDelegate) {
        super.init(frame: .zero)
        self.delegate = delegate
        label.text = title

        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.top.equalToSuperview().offset(20)
        }
        addSubview(textView)
        if text?.isEmpty == false {
            textView.text = text
            textView.textColor = UDColor.textTitle
            isPlaceHolderOpportunity = false
        } else {
            textView.text = BundleI18n.SKResource.Doc_Reminder_Notify_Notes_PlaceHolder
            textView.textColor = UDColor.textPlaceholder
            isPlaceHolderOpportunity = true
        }
        textView.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(13)
            make.leading.equalTo(label)
            make.trailing.equalToSuperview().offset(-16)
            make.height.greaterThanOrEqualTo(32)
            make.bottom.equalToSuperview()
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !textView.frame.contains(point) {
            textView.endEditing(true)
        }
        return super.hitTest(point, with: event)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == BundleI18n.SKResource.Doc_Reminder_Notify_Notes_PlaceHolder && isPlaceHolderOpportunity {
            textView.text = ""
            textView.textColor = UDColor.textTitle
        }
        textView.layer.ud.setBorderColor(UDColor.colorfulBlue)
    }

    func textViewDidChange(_ textView: UITextView) {
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let newHeight = textView.text
            .boundingRect(with: CGSize(width: textView.frame.width - textView.textContainerInset.left - textView.textContainerInset.right,
                                       height: .greatestFiniteMagnitude),
                          options: option,
                          attributes: attributes,
                          context: nil).height
        delegate?.textDidChange(to: textView.text, heightDiff: { (oldText) -> CGFloat in
            guard let oldText = oldText else { return newHeight }
            let oldHeight = (oldText as NSString)
                .boundingRect(with: CGSize(width: textView.frame.width - textView.textContainerInset.left - textView.textContainerInset.right,
                                           height: .greatestFiniteMagnitude),
                              options: option,
                              attributes: attributes,
                              context: nil).height
            return newHeight - oldHeight
        })
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewDidEndEditing(textView)
        if !textView.hasText || textView.text.isEmpty {
            textView.text = BundleI18n.SKResource.Doc_Reminder_Notify_Notes_PlaceHolder
            textView.textColor = UDColor.textPlaceholder
            isPlaceHolderOpportunity = true
        } else {
            isPlaceHolderOpportunity = false
        }
        textView.layer.ud.setBorderColor(UDColor.N400)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

protocol ReminderTextViewDelegate: AnyObject {
    func textDidChange(to: String?, heightDiff: (String?) -> CGFloat)
    func textViewDidEndEditing(_: UITextView)
}

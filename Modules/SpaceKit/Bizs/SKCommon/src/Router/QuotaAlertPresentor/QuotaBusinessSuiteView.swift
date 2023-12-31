//
//  SuiteTypeView.swift
//  SKCommon
//
//  Created by majie on 2021/9/3.
//

import Foundation
import SKResource

public struct SetViewTitleContext {
    public let leftSize: String?
    public let midSize: String?
    public let rightSize: String?
    public let leftversion: String
    public let midversion: String
    public let rightVersion: String
}

private class QuotaView: UIView {
    
    var upView: UIView = {
        let view = UIView()
        return view
    }()
    
    var bottomView: UIView = {
        let view = UIView()
        return view
    }()
    
    var quotaSizeLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24.0, weight: .semibold)
        return label
    }()
    
    var versionLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.upView)
        self.addSubview(self.bottomView)
        upView.addSubview(self.quotaSizeLabel)
        upView.addSubview(self.versionLabel)
        
        upView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-3.0)
        }
        
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(upView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        quotaSizeLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(26.0)
            make.height.equalTo(32.0)
        }
        
        versionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(quotaSizeLabel.snp.bottom).offset(2.0)
            make.height.equalTo(22.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLabelTitle(quotaSize: String, version: String) {
        self.quotaSizeLabel.text = quotaSize
        self.versionLabel.text = version
    }
    
    func setViewColor(up: UIColor, bottom: UIColor, text: UIColor) {
        upView.backgroundColor = up
        bottomView.backgroundColor = bottom
        versionLabel.textColor = text
        quotaSizeLabel.textColor = text
    }
}

public final class QuotaBusinessSuiteView: UIView {
    let quotaViewWidth: CGFloat = 101.0
    fileprivate var leftQuotaView: QuotaView = {
       let view = QuotaView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 3.0
        view.setViewColor(up: UIColor.ud.N100, bottom: UIColor.ud.N500, text: UIColor.ud.N600)
        view.isHidden = true
        return view
    }()
    
    fileprivate var midQuotaView: QuotaView = {
        let view = QuotaView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 3.0
        view.setViewColor(up: UIColor.ud.B50, bottom: UIColor.ud.colorfulBlue, text: UIColor.ud.B700)
        view.isHidden = true
        return view
    }()
    
    fileprivate var rightQuotaView: QuotaView = {
        let view = QuotaView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 3.0
        view.setViewColor(up: UIColor.ud.G50, bottom: UIColor.ud.colorfulGreen, text: UIColor.ud.G700)
        view.isHidden = true
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(leftQuotaView)
        self.addSubview(midQuotaView)
        self.addSubview(rightQuotaView)
        
        leftQuotaView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16.0)
            make.bottom.equalToSuperview().offset(-16.0)
            make.left.equalToSuperview()
            make.width.equalTo(quotaViewWidth)
        }
        
        midQuotaView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16.0)
            make.left.equalTo(leftQuotaView.snp.right).offset(8.0)
            make.width.equalTo(quotaViewWidth)
            make.bottom.equalToSuperview().offset(-16.0)
        }
        
        rightQuotaView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16.0)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16.0)
            make.left.equalTo(midQuotaView.snp.right).offset(8.0)
            make.width.equalTo(quotaViewWidth)
        }
    }
    
    func setViewTitle(context: SetViewTitleContext) {
        if let leftSize = context.leftSize {
            self.leftQuotaView.setLabelTitle(quotaSize: leftSize, version: context.leftversion)
            self.leftQuotaView.isHidden = false
        }
        if let midSize = context.midSize {
            self.midQuotaView.setLabelTitle(quotaSize: midSize, version: context.midversion)
            self.midQuotaView.isHidden = false
        }
        if let rightSize = context.rightSize {
            self.rightQuotaView.setLabelTitle(quotaSize: rightSize, version: context.rightVersion)
            self.rightQuotaView.isHidden = false
        }
        remakeConstraints()
    }
    
    private func remakeConstraints() {
        let leftWidth = leftQuotaView.isHidden ? 0 : quotaViewWidth
        leftQuotaView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(16.0)
            make.bottom.equalToSuperview().offset(-16.0)
            make.left.equalToSuperview()
            make.width.equalTo(leftWidth)
        }
        let midWidth = midQuotaView.isHidden ? 0 : quotaViewWidth
        let midMargin = midQuotaView.isHidden ? 0 : 8.0
        midQuotaView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(16.0)
            make.left.equalTo(leftQuotaView.snp.right).offset(midMargin)
            make.width.equalTo(midWidth)
            make.bottom.equalToSuperview().offset(-16.0)
        }
        let rightWidth = rightQuotaView.isHidden ? 0 : quotaViewWidth
        let rightMargin = rightQuotaView.isHidden ? 0 : 8.0
        rightQuotaView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(16.0)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16.0)
            make.left.equalTo(midQuotaView.snp.right).offset(rightMargin)
            make.width.equalTo(rightWidth)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
//  PickerContactView.swift
//  LarkContact
//
//  Created by Yuri on 2023/4/10.
//

import UIKit
import SnapKit
import UniverseDesignColor
import LarkContainer
import LarkSearchCore
import LarkModel

public protocol PickerContactViewDelegate: AnyObject {
    func contactViewDidSelect(item: PickerItem, at category: PickerItemCategory)
    func contactViewDidCancelMultiSelect(item: PickerItem, at category: PickerItemCategory)
    func contactViewDidFinish(items: [PickerItem], at category: PickerItemCategory)
    func contactViewDidDisable(item: PickerItem, at category: PickerItemCategory) -> Bool
}

extension PickerContactViewDelegate {
    func contactViewDidSelect(item: PickerItem, at category: PickerItemCategory) {}
    func contactViewDidCancelMultiSelect(item: PickerItem, at category: PickerItemCategory) {}
    func contactViewDidFinish(items: [PickerItem], at category: PickerItemCategory) {}
    func contactViewDidDisable(item: PickerItem, at category: PickerItemCategory) -> Bool {
        return false
    }
}

final public class PickerContactView: UIView, PickerDefaultViewType {

    public weak var delegate: PickerContactViewDelegate?

    private var contactView: StructureView?
    private var picker: ChatterPicker?
    public var config = PickerContactViewConfig(entries: [])

    let resolver: UserResolver
    public init(resolver: UserResolver) {
        self.resolver = resolver
        super.init(frame: .zero)
    }

    public init(userId: String) throws {
        self.resolver = try Container.shared.getUserResolver(userID: userId)
        super.init(frame: .zero)
    }

    deinit {
        ContactLogger.shared.info(module: .view, event: "\(self.self) deinit")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
    }

    public func bind(picker: SearchPickerView) {
        PickerLogger.shared.info(module: PickerLogger.Module.contact, event: "init contact view") {
            do {
                let data = try JSONEncoder().encode(self.config)
                let string = String(data: data, encoding: .utf8) ?? ""
                return string
            } catch {
                return "error: \(error.localizedDescription)"
            }
        }
        var config = StructureViewDependencyConfig()
        let entries = self.config.entries
        let hasOwnedGroup = entries.contains(where: { $0 is PickerContactViewConfig.OwnedGroup })
        let hasExternal = entries.contains(where: { $0 is PickerContactViewConfig.External })
        let hasRelatedOrganization = entries.contains(where: { $0 is PickerContactViewConfig.RelatedOrganization })
        let hasEmailContact = entries.contains(where: { $0 is PickerContactViewConfig.EmailContact })
        let hasUserGroup = entries.contains(where: { $0 is PickerContactViewConfig.UserGroup })
        config.enableGroup = hasOwnedGroup
        config.enableOwnedGroup = hasOwnedGroup
        config.enableExternal = hasExternal
        config.enableRelatedOrganizations = hasRelatedOrganization
        config.enableEmailContact = hasEmailContact
        config.tableBackgroundColor = UIColor.ud.bgBase
        if let organization = entries.first(where: { $0 is PickerContactViewConfig.Organization }) as? PickerContactViewConfig.Organization {
            config.enableOrganization = true
            config.preferEnterpriseEmail = organization.preferEnterpriseEmail
        }
        if hasUserGroup {
//            config.enableUserGroup = true
            config.userGroupSceneType = .ccm
        }

        let dependency = DefaultStructureViewDependencyImpl(r: resolver, picker: picker, config: config)
        let contactView = StructureView(frame: .zero, dependency: dependency, resolver: resolver)
        self.contactView = contactView
        contactView.targetVC = picker.btd_viewController()
        contactView.delegate = delegate
        addSubview(contactView)
        contactView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        render()
    }
}

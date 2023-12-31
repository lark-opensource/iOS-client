//
//  OrientationObserver.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/10.
//  

import SKFoundation

class OrientationObserver {
    enum Source: String {
        case image
        case doc
    }

    let docsInfo: DocsInfo?
    let source: Source

    init(docsInfo: DocsInfo?, source: Source) {
        self.docsInfo = docsInfo
        self.source = source
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

extension OrientationObserver {
    @objc
    private func orientationDidChange() {
        trackForOrientationDidChange()
    }
    private func trackForOrientationDidChange() {
        guard let info = docsInfo else { return }
        var parameters: [String: Any] = [:]
        parameters["file_type"] = info.type.name
        parameters["file_id"] = DocsTracker.encrypt(id: info.objToken)
        parameters["module"] = info.type.name
        parameters["source"] = source.rawValue
        DocsLogger.debug("[旋转埋点] \(parameters)")
        DocsTracker.log(enumEvent: .clientHorizontalScreen, parameters: parameters)
    }
}

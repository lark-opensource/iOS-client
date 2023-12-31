//
//  CoverSelectPanelViewModelTests.swift
//  SKDoc_Tests-Unit-_Tests
//
//  Created by GuoXinyi on 2022/9/25.
//

import Foundation
@testable import SKDoc
@testable import SKCommon
@testable import SKBrowser
import SpaceInterface
import XCTest

class CoverSelectPanelViewModelTests: XCTestCase {
    
    private var viewModel: CoverSelectPanelViewModel!
    
    override func setUp() {
        super.setUp()
        let token = "doxcnFzuogEsCRUFN7gunPk7M2e"
        let docsType = DocsType.docX.rawValue
        let provider = OfficialCoverPhotosProvider()
        viewModel = CoverSelectPanelViewModel(netWorkAPI: provider, sourceDocumentInfo: (token, docsType), selectCoverInfo: nil, model: nil)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testShowSelectCoverPanel() {
        viewModel.selectCoverInfo = ("doxcnFzuogEsCRUFN7gunPk7M2e", DocsType.docX.rawValue)
        let vc = CoverSelectPanelViewController(viewModel: viewModel)
    }
    
    func testShowFailedTips() {
        viewModel.showFailedTips("test")
        let image = UIColor.orange.testImage(CGSize(width: 128, height: 128))
        guard image != nil else {
            return
        }
        viewModel.handleTakeLocalCoverPhoto(image)
    }
}

extension UIColor {
    func testImage(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

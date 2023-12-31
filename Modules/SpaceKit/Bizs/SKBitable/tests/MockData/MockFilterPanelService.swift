//
//  MockFilterPanelService.swift
//  SKBitable_Tests
//
//  Created by zengsenyuan on 2022/8/4.
//  


@testable import SKBitable
import RxSwift
import RxCocoa

class MockFilterPanelService: BTFilterPanelDataServiceType {
    
    func updateFilterInfo(type: BTSetFilterType, value: Any, callback: String) -> Single<Bool> {
        return .just(true)
    }
}

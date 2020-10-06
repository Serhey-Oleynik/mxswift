//
//  ObservableConvertibleType+Infallible.swift
//  RxSwift
//
//  Created by Shai Mishali on 27/08/2020.
//  Copyright © 2020 Krunoslav Zaher. All rights reserved.
//

extension ObservableConvertibleType {
    func asInfallible(onErrorJustReturn element: Element) -> Infallible<Element> {
        Infallible(self.asObservable().catchErrorJustReturn(element))
    }

    func asInfallible(onErrorFallbackTo infallible: Infallible<Element>) -> Infallible<Element> {
        Infallible(self.asObservable().catchError { _ in infallible.asObservable() })
    }

    func asInfallible(onErrorRecover: @escaping (Swift.Error) -> Infallible<Element>) -> Infallible<Element> {
        Infallible(asObservable().catchError { onErrorRecover($0).asObservable() })
    }
}

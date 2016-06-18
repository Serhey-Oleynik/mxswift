//
//  Reduce.swift
//  Rx
//
//  Created by Krunoslav Zaher on 4/1/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

class ReduceSink<SourceType, AccumulateType, O: ObserverType> : Sink<O>, ObserverType {
    typealias ResultType = O.E
    typealias Parent = Reduce<SourceType, AccumulateType, ResultType>
    
    private let _parent: Parent
    private var _accumulation: AccumulateType
    
    init(parent: Parent, observer: O) {
        _parent = parent
        _accumulation = parent._seed
        
        super.init(observer: observer)
    }
    
    func on(_ event: Event<SourceType>) {
        switch event {
        case .next(let value):
            do {
                _accumulation = try _parent._accumulator(_accumulation, value)
            }
            catch let e {
                forwardOn(.error(e))
                dispose()
            }
        case .error(let e):
            forwardOn(.error(e))
            dispose()
        case .completed:
            do {
                let result = try _parent._mapResult(_accumulation)
                forwardOn(.next(result))
                forwardOn(.completed)
                dispose()
            }
            catch let e {
                forwardOn(.error(e))
                dispose()
            }
        }
    }
}

class Reduce<SourceType, AccumulateType, ResultType> : Producer<ResultType> {
    typealias AccumulatorType = (AccumulateType, SourceType) throws -> AccumulateType
    typealias ResultSelectorType = (AccumulateType) throws -> ResultType
    
    private let _source: Observable<SourceType>
    private let _seed: AccumulateType
    private let _accumulator: AccumulatorType
    private let _mapResult: ResultSelectorType
    
    init(source: Observable<SourceType>, seed: AccumulateType, accumulator: AccumulatorType, mapResult: ResultSelectorType) {
        _source = source
        _seed = seed
        _accumulator = accumulator
        _mapResult = mapResult
    }
    
    override func run<O: ObserverType where O.E == ResultType>(_ observer: O) -> Disposable {
        let sink = ReduceSink(parent: self, observer: observer)
        sink.disposable = _source.subscribe(sink)
        return sink
    }
}

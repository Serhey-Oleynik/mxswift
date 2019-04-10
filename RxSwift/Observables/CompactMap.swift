//
//  CompactMap.swift
//  RxSwift
//
//  Created by Michael Long on 04/09/2019.
//
//

extension ObservableType {

    /**
     Projects each element of an observable sequence into an optional form and filters all optional results.

     Equivalent to:

     func compactMap<R>(_ transform: @escaping (Self.E) throws -> R?) -> RxSwift.Observable<R> {
        return self.map { try? transform($0) }.filter { $0 != nil }.map { $0! }
     }

     - parameter transform: A transform function to apply to each source element and which returns an element or nil.
     - returns: An observable sequence whose elements are the result of filtering the transform function for each element of the source.

     */
    public func compactMap<R>(_ transform: @escaping (E) throws -> R?)
        -> Observable<R> {
            return CompactMap(source: self.asObservable(), transform: transform)
    }
}

final private class CompactMapSink<SourceType, O: ObserverType>: Sink<O>, ObserverType {
    typealias Transform = (SourceType) throws -> ResultType?

    typealias ResultType = O.E
    typealias Element = SourceType

    private let _transform: Transform

    init(transform: @escaping Transform, observer: O, cancel: Cancelable) {
        self._transform = transform
        super.init(observer: observer, cancel: cancel)
    }

    func on(_ event: Event<SourceType>) {
        switch event {
        case .next(let element):
            do {
                if let mappedElement = try self._transform(element) {
                    self.forwardOn(.next(mappedElement))
                }
            }
            catch let e {
                self.forwardOn(.error(e))
                self.dispose()
            }
        case .error(let error):
            self.forwardOn(.error(error))
            self.dispose()
        case .completed:
            self.forwardOn(.completed)
            self.dispose()
        }
    }
}

final private class CompactMap<SourceType, ResultType>: Producer<ResultType> {
    typealias Transform = (SourceType) throws -> ResultType?

    private let _source: Observable<SourceType>

    private let _transform: Transform

    init(source: Observable<SourceType>, transform: @escaping Transform) {
        self._source = source
        self._transform = transform
    }

    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == ResultType {
        let sink = CompactMapSink(transform: self._transform, observer: observer, cancel: cancel)
        let subscription = self._source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
}

//
//  GQLDecoder.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/5/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation

protocol GQLDecoder {
    associatedtype Input
    associatedtype Output
    func decode(_ type: Output.Type, from data: Input) throws -> Output
}

private class _AnyGQLDecoderBase<Input, Output>: GQLDecoder {
    func decode(_ type: Output.Type, from data: Input) throws -> Output {
        fatalError()
    }
}

private final class _AnyGQLDecoderBox<Concrete: GQLDecoder>: _AnyGQLDecoderBase<Concrete.Input, Concrete.Output> {
    var concrete: Concrete
    init(_ concrete: Concrete) {
        self.concrete = concrete
    }
    override func decode(_ type: Concrete.Output.Type, from data: Input) throws -> Concrete.Output {
        return try concrete.decode(type, from: data)
    }
}

final class AnyGQLDecoder<Input, Output>: GQLDecoder {
    private let box: _AnyGQLDecoderBase<Input, Output>
    init<Concrete: GQLDecoder>(_ concrete: Concrete) where Concrete.Input == Input, Concrete.Output == Output {
        self.box = _AnyGQLDecoderBox(concrete)
    }
    func decode(_ type: Output.Type, from data: Input) throws -> Output {
        return try box.decode(type, from: data)
    }
}


struct CollectionDecoder<Input, Output>: GQLDecoder where Input: Sequence, Output: Sequence, Output.Element: GQLDecodable, Output.Element.Fragment == Input.Element, Output: ExpressibleByArrayLiteral {
    func decode(_ type: Output.Type, from data: Input) throws -> Output {

        guard let output = data.compactMap(Output.Element.init) as? Output else {
            throw QueryError.decodingError
        }
        return output
    }
}

struct ObjectDecoder<Input, Output>: GQLDecoder where Output: GQLDecodable, Input == Output.Fragment {
    func decode(_ type: Output.Type, from data: Input) throws -> Output {
        guard let output = Output.init(data) else {
            throw QueryError.decodingError
        }
        return output
    }
}

struct ScalarDecoder<Input, Output>: GQLDecoder {
    func decode(_ type: Output.Type, from data: Input) throws -> Output {
        if let data = data as? Output {
            return data
        } else {
            throw QueryError.decodingError
        }
    }
}

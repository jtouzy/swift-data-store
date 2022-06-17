//
//  XCTestCase+Combine.swift
//  DataStoreTests
//
//  Copyright © 2022 Jérémy TOUZY and the repository contributors.
//  Licensed under the MIT License.
//

import Combine
import XCTest

extension XCTestCase {
  public func asyncPublisherValues<T: Publisher>(
    _ publisher: T,
    afterSink afterSinkActionCallback: @escaping () async throws -> Void,
    file: StaticString = #file,
    line: UInt = #line
  ) async throws -> [Result<T.Output, T.Failure>] {
    var results: [Result<T.Output, T.Failure>] = []
    let cancellable = publisher.sink(
      receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          results.append(.failure(error))
        case .finished:
          break
        }
      },
      receiveValue: { value in
        results.append(.success(value))
      }
    )
    try await afterSinkActionCallback()
    cancellable.cancel()
    return results
  }
}

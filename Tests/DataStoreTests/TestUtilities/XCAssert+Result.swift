//
//  XCTAssertEqual+Result.swift
//  DataStoreTests
//
//  Copyright © 2022 Jérémy TOUZY and the repository contributors.
//  Licensed under the MIT License.
//

import XCTest

public func XCTAssertEqual<Output, Failure>(
  _ firstResults: [Result<Output, Failure>],
  _ secondResults: [Result<Output, Failure>],
  file: StaticString = #file,
  line: UInt = #line
) where Output: Equatable, Failure: Error {
  guard firstResults.count == secondResults.count else {
    XCTFail("The results array has a different size than expected")
    return
  }
  for (index, firstResult) in firstResults.enumerated() {
    let secondResult = secondResults[index]
    XCTAssertEqual(firstResult, secondResult)
  }
}

public func XCTAssertEqual<Output, Failure>(
  _ firstResult: Result<Output, Failure>,
  _ secondResult: Result<Output, Failure>,
  file: StaticString = #file,
  line: UInt = #line
) where Output: Equatable, Failure: Error {
  switch firstResult {
  case .success(let output):
    if case let .success(secondOutput) = secondResult {
      XCTAssertEqual(
        output,
        secondOutput,
        file: file,
        line: line
      )
    } else {
      XCTFail(
        "Result is success, but expected result is failure",
        file: file,
        line: line
      )
    }
  case .failure(let error):
    if case let .failure(secondError) = secondResult {
      XCTAssertEqual(
        String(reflecting: error),
        String(reflecting: secondError),
        file: file,
        line: line
      )
    } else {
      XCTFail(
        "Result is failure [\(String(reflecting: error))], but expected result is success",
        file: file,
        line: line
      )
    }
  }
}

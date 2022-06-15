//
//  UserDefaultsKeyValueDataStoreTests.swift
//  DataStoreTests
//
//  Copyright © 2022 Jérémy TOUZY and the repository contributors.
//  Licensed under the MIT License.
//

@testable import DataStore

import XCTest

final class UserDefaultsKeyValueDataStoreTests: XCTestCase {
  private func createSUT() -> UserDefaultsKeyValueDataStore {
    .init()
  }
  struct TestableData: Codable, Equatable {
    let title: String
  }
}

extension UserDefaultsKeyValueDataStoreTests {
  func test_read_emptyPath() async throws {
    // Given
    let sut = createSUT()
    // When
    let value: TestableData? = try await sut.read(forKey: "test_read_emptyPath")
    // Then
    XCTAssertNil(value)
  }
  func test_read_happyPath() async throws {
    // Given
    let testableData = TestableData(title: "test_read_happyPath_title")
    let sut = createSUT()
    // When
    try await sut.store(testableData, forKey: "test_read_happyPath")
    let value: TestableData? = try await sut.read(forKey: "test_read_happyPath")
    // Then
    let unwrappedValue = try XCTUnwrap(value)
    XCTAssertEqual(unwrappedValue, .init(title: "test_read_happyPath_title"))
  }
}

extension UserDefaultsKeyValueDataStoreTests {
  func test_store_happyPath() async throws {
    // Given
    let testableData = TestableData(title: "test_store_happyPath_title")
    let sut = createSUT()
    // When
    let result = try await sut.store(testableData, forKey: "test_store_happyPath")
    // Then
    XCTAssertEqual(result, .init(title: "test_store_happyPath_title"))
    let storedData = try XCTUnwrap(UserDefaults.standard.data(forKey: "test_store_happyPath"))
    let decoded = try sut.decoder.decode(TestableData.self, from: storedData)
    XCTAssertEqual(decoded, result)
  }
}

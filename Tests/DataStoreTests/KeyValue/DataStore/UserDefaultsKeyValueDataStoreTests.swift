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
    sut.userDefaults.removeObject(forKey: "test_read_emptyPath")
    // When
    let value: TestableData? = try await sut.read(forKey: "test_read_emptyPath")
    // Then
    XCTAssertNil(value)
  }
  func test_read_happyPath() async throws {
    // Given
    let testableData = TestableData(title: "test_read_happyPath_title")
    let sut = createSUT()
    sut.userDefaults.removeObject(forKey: "test_read_happyPath")
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
    sut.userDefaults.removeObject(forKey: "test_store_happyPath")
    // When
    let result = try await sut.store(testableData, forKey: "test_store_happyPath")
    // Then
    XCTAssertEqual(result, .init(title: "test_store_happyPath_title"))
    let storedData = try XCTUnwrap(UserDefaults.standard.data(forKey: "test_store_happyPath"))
    let decoded = try sut.decoder.decode(TestableData.self, from: storedData)
    XCTAssertEqual(decoded, result)
  }
}

extension UserDefaultsKeyValueDataStoreTests {
  func test_publisher() async throws {
    // Given
    let testableData_1 = TestableData(title: "test_publisher_title")
    let testableData_2 = TestableData(title: "test_publisher_title_2")
    let sut = createSUT()
    sut.userDefaults.removeObject(forKey: "test_publisher")
    sut.userDefaults.removeObject(forKey: "test_publisher_other_key")
    // When
    let publisherValues: [Result<TestableData, Error>] = try await asyncPublisherValues(
      sut.publisher(forKey: "test_publisher"),
      afterSink: {
        try await sut.store(testableData_1, forKey: "test_publisher")
        // NOTE: This should not be stored, it's a complete separate key
        try await sut.store(testableData_1, forKey: "test_publisher_other_key")
        try await sut.store(testableData_2, forKey: "test_publisher")
      }
    )
    // Then
    XCTAssertEqual(
      publisherValues,
      [.success(.init(title: "test_publisher_title")), .success(.init(title: "test_publisher_title_2"))]
    )
  }
}

//
//  InMemoryKeyValueDataStore.swift
//  DataStore
//
//  Copyright © 2022 Jérémy TOUZY and the repository contributors.
//  Licensed under the MIT License.
//

import Combine

public actor InMemoryKeyValueDataStore: KeyValueDataStore {
  private var values: [String: Any] = [:]

  internal init() {
  }
}

extension InMemoryKeyValueDataStore {
  public func read<T>(forKey key: String) async throws -> T? where T: Codable & Sendable {
    guard let value = values[key] as? T else {
      return .none
    }
    return value
  }
  @discardableResult
  public func store<T>(_ value: T, forKey key: String) async throws -> T where T: Codable & Sendable {
    values[key] = value
    return value
  }
  public nonisolated func publisher<T>(forKey key: String) -> AnyPublisher<T, Error> where T: Codable {
    preconditionFailure("Not implemented yet")
  }
}

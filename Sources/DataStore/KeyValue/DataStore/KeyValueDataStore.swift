//
//  KeyValueDataStore.swift
//  DataStore
//
//  Copyright © 2022 Jérémy TOUZY and the repository contributors.
//  Licensed under the MIT License.
//

import Combine

public protocol KeyValueDataStore {
  func read<T>(forKey key: String) async throws -> T? where T: Codable & Sendable
  @discardableResult func store<T>(_ value: T, forKey key: String) async throws -> T where T: Codable & Sendable
  func publisher<T>(forKey key: String) -> AnyPublisher<T, Swift.Error> where T: Codable
  func stream<T>(forKey key: String) -> AsyncStream<T> where T: Codable
}

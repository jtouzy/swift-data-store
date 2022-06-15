//
//  KeyValueStorage.swift
//  DataStore
//
//  Copyright © 2022 Jérémy TOUZY and the repository contributors.
//  Licensed under the MIT License.
//

public struct KeyValueStorage<T> where T: Codable & Sendable {
  public typealias GetInitialValue = () async throws -> T
  public typealias StoreInitialValue = () async throws -> T

  public let key: String
  public let storeInitialValue: StoreInitialValue
  public let dataStore: KeyValueDataStore

  internal init(
    key: String,
    initialValue: @escaping GetInitialValue,
    dataStore: KeyValueDataStore
  ) {
    self.key = key
    self.storeInitialValue = {
      let value = try await initialValue()
      return try await dataStore.store(value, forKey: key)
    }
    self.dataStore = dataStore
  }

  public func read() async throws -> T {
    guard let storedValue: T = try await dataStore.read(forKey: key) else {
      return try await storeInitialValue()
    }
    return storedValue
  }
  public func store(_ value: T) async throws -> T {
    try await dataStore.store(value, forKey: key)
  }
}

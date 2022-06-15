//
//  UserDefaultsKeyValueDataStore.swift
//  DataStore
//
//  Copyright © 2022 Jérémy TOUZY and the repository contributors.
//  Licensed under the MIT License.
//

import Combine
import Foundation

public class UserDefaultsKeyValueDataStore: KeyValueDataStore {
  public let userDefaults: UserDefaults
  public let decoder: JSONDecoder
  public let encoder: JSONEncoder

  public init(
    userDefaults: UserDefaults = .standard,
    decoder: JSONDecoder = .init(),
    encoder: JSONEncoder = .init()
  ) {
    self.userDefaults = userDefaults
    self.decoder = decoder
    self.encoder = encoder
  }

  public func read<T>(forKey key: String) async throws -> T?
  where T: Codable, T: Sendable {
    guard let storedData = userDefaults.data(forKey: key) else {
      return .none
    }
    return try decoder.decode(T.self, from: storedData)
  }

  @discardableResult
  public func store<T>(_ value: T, forKey key: String) async throws -> T
  where T: Codable, T: Sendable {
    let encoded = try encoder.encode(value)
    userDefaults.setValue(encoded, forKey: key)
    return value
  }

  public func publisher<T>(forKey key: String) -> AnyPublisher<T, Swift.Error>
  where T: Codable {
    UserDefaultsKeyObservation(key: key, on: userDefaults)
      .publisher()
      .tryMap { [weak decoder] storedData in
        guard let decoder = decoder else { throw Error.unreachableJsonDecoder }
        return try decoder.decode(T.self, from: storedData)
      }
      .eraseToAnyPublisher()
  }
}

extension UserDefaultsKeyValueDataStore {
  enum Error: Swift.Error {
    case unreachableJsonDecoder
  }
}

private class UserDefaultsKeyObservation: NSObject {
  let key: String
  private let subject: PassthroughSubject<Data, Never> = .init()

  init(key: String, on userDefaults: UserDefaults) {
    self.key = key
    super.init()
    userDefaults.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
  }

  func publisher() -> AnyPublisher<Data, Never> {
    subject.eraseToAnyPublisher()
  }

  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey : Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    guard object != nil, keyPath == key, let new = change?[.newKey] as? Data else {
      return
    }
    subject.send(new)
  }
}

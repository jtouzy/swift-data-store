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
    UserDefaultsPublisher(key: key, userDefaults: userDefaults)
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

private struct UserDefaultsPublisher: Publisher {
  typealias Output = Data
  typealias Failure = Never

  private let key: String
  private let userDefaults: UserDefaults

  init(key: String, userDefaults: UserDefaults) {
    self.key = key
    self.userDefaults = userDefaults
  }

  func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    let subscription = UserDefaultsSubscription(
      subscriber: subscriber,
      key: key,
      userDefaults: userDefaults
    )
    subscriber.receive(subscription: subscription)
  }
}

private final class UserDefaultsSubscription<SubscriberType: Subscriber>: Subscription
where SubscriberType.Input == Data {
  private var subscriber: SubscriberType?
  private var observation: UserDefaultsKeyObservation?

  init(
    subscriber: SubscriberType,
    key: String,
    userDefaults: UserDefaults
  ) {
    self.subscriber = subscriber
    self.observation = UserDefaultsKeyObservation(key: key, on: userDefaults) { newValue in
      _ = subscriber.receive(newValue)
    }
  }

  func request(_ demand: Subscribers.Demand) {
  }

  func cancel() {
    observation = nil
    subscriber = nil
  }
}

private class UserDefaultsKeyObservation: NSObject {
  typealias Callback = (Data) -> Void

  let key: String
  let userDefaults: UserDefaults
  let callback: Callback

  init(key: String, on userDefaults: UserDefaults, callback: @escaping Callback) {
    self.key = key
    self.userDefaults = userDefaults
    self.callback = callback
    super.init()
    userDefaults.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
  }

  deinit {
    userDefaults.removeObserver(self, forKeyPath: key)
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
    callback(new)
  }
}

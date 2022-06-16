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
}

// MARK: Basic API

extension UserDefaultsKeyValueDataStore {
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
}

// MARK: AsyncSequence related

extension UserDefaultsKeyValueDataStore {
  public func stream<T>(forKey key: String) -> AsyncStream<T>
  where T: Codable {
    AsyncStream(T.self) { continuation in
      let observation = UserDefaultsKeyObservation<T>(key: key, on: userDefaults, decoder: decoder) { result in
        continuation.yield(result)
      }
      continuation.onTermination = { _ in
        observation.stopObserving()
      }
    }
  }
}

// MARK: Combine related

extension UserDefaultsKeyValueDataStore {
  public func publisher<T>(forKey key: String) -> AnyPublisher<T, Swift.Error>
  where T: Codable {
    UserDefaultsPublisher(
      key: key,
      userDefaults: userDefaults,
      decoder: decoder
    )
    .eraseToAnyPublisher()
  }
}

extension UserDefaultsKeyValueDataStore {
  enum Error: Swift.Error {
    case unreachableJsonDecoder
  }
}

private struct UserDefaultsPublisher<T>: Publisher where T: Codable {
  typealias Output = T
  typealias Failure = Error

  private let key: String
  private let userDefaults: UserDefaults
  private let decoder: JSONDecoder

  init(key: String, userDefaults: UserDefaults, decoder: JSONDecoder) {
    self.key = key
    self.userDefaults = userDefaults
    self.decoder = decoder
  }

  func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    let subscription = UserDefaultsSubscription(
      subscriber: subscriber,
      key: key,
      userDefaults: userDefaults,
      decoder: decoder
    )
    subscriber.receive(subscription: subscription)
  }
}

private final class UserDefaultsSubscription<SubscriberType: Subscriber>: Subscription
where SubscriberType.Input: Codable {
  private var subscriber: SubscriberType?
  private var observation: UserDefaultsKeyObservation<SubscriberType.Input>?

  init(
    subscriber: SubscriberType,
    key: String,
    userDefaults: UserDefaults,
    decoder: JSONDecoder
  ) {
    self.subscriber = subscriber
    self.observation = UserDefaultsKeyObservation(key: key, on: userDefaults, decoder: decoder) { newValue in
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

// MARK: Internal key-value observation

private class UserDefaultsKeyObservation<T>: NSObject where T: Codable {
  typealias Callback = (T) -> Void

  let key: String
  let userDefaults: UserDefaults
  let decoder: JSONDecoder
  let callback: Callback

  init(key: String, on userDefaults: UserDefaults, decoder: JSONDecoder, callback: @escaping Callback) {
    self.key = key
    self.userDefaults = userDefaults
    self.decoder = decoder
    self.callback = callback
    super.init()
    userDefaults.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
  }

  deinit {
    stopObserving()
  }

  func stopObserving() {
    userDefaults.removeObserver(self, forKeyPath: key)
  }

  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey : Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    guard object != nil, keyPath == key, let newValue = change?[.newKey] as? Data else {
      return
    }
    do {
      let decodedValue = try decoder.decode(T.self, from: newValue)
      callback(decodedValue)
    } catch {
    }
  }
}

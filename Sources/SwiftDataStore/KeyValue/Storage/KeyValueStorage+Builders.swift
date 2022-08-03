//
//  KeyValueStorage+Builders.swift
//  DataStore
//
//  Copyright © 2022 Jérémy TOUZY and the repository contributors.
//  Licensed under the MIT License.
//

import Foundation

extension KeyValueStorage {
  public static func withInitial(
    key: String,
    value: T,
    dataStore: KeyValueDataStore
  ) -> KeyValueStorage<T> {
    .init(
      key: key,
      initialValue: { value },
      dataStore: dataStore
    )
  }
}

extension KeyValueStorage {
  public static func withBundleFileAsInitial(
    key: String,
    fromBundleFile bundleFile: String,
    in bundle: Bundle,
    dataStore: KeyValueDataStore
  ) -> KeyValueStorage<T> {
    .init(
      key: key,
      initialValue: {
        try bundle.decode(fromFile: bundleFile)
      },
      dataStore: dataStore
    )
  }
}

private extension Bundle {
  enum FileError: Swift.Error {
    case fileNotFound
    case contentsUnreadable(Swift.Error)
    case contentsUndecodable(Swift.Error)
  }
  func decode<T>(
    fromFile bundleFile: String,
    decoder: JSONDecoder = .init()
  ) throws -> T where T: Decodable {
    guard let filePath = url(
      forResource: bundleFile,
      withExtension: "json"
    ) else {
      throw FileError.fileNotFound
    }
    var fileContents: Data
    do {
      fileContents = try Data(contentsOf: filePath)
    } catch {
      throw FileError.contentsUnreadable(error)
    }
    var result: T
    do {
      result = try decoder.decode(T.self, from: fileContents)
    } catch {
      throw FileError.contentsUndecodable(error)
    }
    return result
  }
}

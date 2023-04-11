//
//  FileManager+Extension.swift
//  AISensei
//
//  Created by k2o on 2023/04/10.
//

import Foundation

extension FileManager {
    /// ユーザドメインのディレクトリURLを求める。
    ///
    /// - Parameter directory: ディレクトリ種別
    /// - Returns: URLを返す
    public func userDirectory(for directory: FileManager.SearchPathDirectory) -> URL {
        return try! url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
        
    /// ドキュメントディレクトリのURLを参照する。
    public var documentDirectory: URL {
        return userDirectory(for: .documentDirectory)
    }

    public var applicationSupportDirectory: URL {
        return userDirectory(for: .applicationSupportDirectory)
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "")
    }

    /// キャッシュディレクトリのURLを参照する。
    public var cachesDirectory: URL {
        return userDirectory(for: .cachesDirectory)
    }
        
    /// ドキュメントディレクトリ配下のファイルURLを求める。
    ///
    /// - Parameter path: 配下のパス
    /// - Returns: URLを返す
    public func documentFileURL(path: String) -> URL {
        return documentDirectory.appendingPathComponent(path)
    }

    public func applicationSupportFileURL(path: String) -> URL {
        return applicationSupportDirectory
            .appendingPathComponent(path)
    }

    /// キャッシュディレクトリ配下のファイルURLを求める。
    ///
    /// - Parameter path: 配下のパス
    /// - Returns: URLを返す
    public func cacheFileURL(path: String) -> URL {
        return cachesDirectory.appendingPathComponent(path)
    }
        
    /// 一時ディレクトリ配下のファイルURLを求める。
    ///
    /// - Parameter path: 配下のパス
    /// - Returns: URLを返す
    public func temporaryFileURL(path: String) -> URL {
        return temporaryDirectory.appendingPathComponent(path)
    }
}

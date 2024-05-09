//
//  XCGWrapper.swift
//  UtilityFeatures/XCGWrapper
//
//  Created by Douglas Adams on 12/20/21.
//

import Combine
import Foundation
import SwiftUI

import XCGLogger
import ObjcExceptionBridging


extension Notification.Name {
  public static let logAlertNotification = Notification.Name("LogAlertNotification")
}



// ----------------------------------------------------------------------------
// MARK: - Public properties

public func log(_ msg: String, _ level: XCGLogger.Level, _ function: StaticString, _ file: StaticString, _ line: Int) {
  //    _logStream( LogEntry(msg, level, function, file, line) )
  
  switch level {
    
  case .debug:    XCGWrapper.shared.log?.debug(msg, functionName: function, fileName: file, lineNumber: line)
  case .info:     XCGWrapper.shared.log?.info(msg, functionName: function, fileName: file, lineNumber: line)
  case .warning:  XCGWrapper.shared.log?.warning(msg, functionName: function, fileName: file, lineNumber: line)
  case .error:    XCGWrapper.shared.log?.error(msg, functionName: function, fileName: file, lineNumber: line)
  case .verbose, .notice, .severe, .alert, .emergency, .none:
    XCGWrapper.shared.log?.error("Invalid Log Level: " + msg, functionName: function, fileName: file, lineNumber: line)
  }
  
  if level == .warning || level == .error {
    NotificationCenter.default.post(name: Notification.Name.logAlertNotification, object: LogEntry(msg, level, function, file, line))
  }
}

//public typealias XCGWrapperLog = Log
//public typealias Log = (_ msg: String, _ level: XCGLogger.Level, _ function: StaticString, _ file: StaticString, _ line: Int) -> Void

//public typealias LogProperty = (_ msg: String, _ level: LogLevel) -> Void

// struct & enums for use in the Log Viewer
public struct LogLine: Identifiable, Equatable, Sendable {
  public var id = UUID()
  public var text: String
  public var color: Color
  
  public init(text: String, color: Color = .primary) {
    self.text = text
    self.color = color
  }
}

public enum LogFilter: String, CaseIterable {
  case none
  case includes
  case excludes
  case prefix
}

//public var logEntries: AsyncStream<LogEntry> {
//  AsyncStream { continuation in _logStream = { logEntry in continuation.yield(logEntry) }
//    continuation.onTermination = { @Sendable _ in } }}

//public var logAlerts: AsyncStream<LogEntry> {
//  AsyncStream { continuation in _logAlertStream = { logEntry in continuation.yield(logEntry) }
//    continuation.onTermination = { @Sendable _ in } }}

public struct LogEntry: Equatable {
  public static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
    guard lhs.msg == rhs.msg else { return false }
    guard lhs.level == rhs.level else { return false }
    guard lhs.level == rhs.level else { return false }
    guard lhs.function.description == rhs.function.description else { return false }
    guard lhs.file.description == rhs.file.description else { return false }
    guard lhs.line == rhs.line else { return false }
    return true
  }
  
  public var msg: String
  public var level: XCGLogger.Level
  public var function: StaticString
  public var file: StaticString
  public var line: Int
  
  public init(_ msg: String, _ level: XCGLogger.Level, _ function: StaticString, _ file: StaticString, _ line: Int ) {
    self.msg = msg
    self.level = level
    self.function = function
    self.file = file
    self.line = line
  }
}

//public enum LogLevel: String, CaseIterable {
//    case debug
//    case info
//    case warning
//    case error
//}

// ----------------------------------------------------------------------------
// MARK: - Private properties

//private var _logStream: (LogEntry) -> Void = { _ in }
private var _logAlertStream: (LogEntry) -> Void = { _ in }

// ----------------------------------------------------------------------------
// MARK: - Global methods

/// Given the domain and App name, ensure that the Log folder exista
/// - Parameters:
///   - info: a tuple of domain and app name
///   - folderUrl: the URL of the log folder
/// - Returns: the URL of the log file (or nil)
//public func setupLogFolder(_ domain: String, _ appName: String, _ folderUrl: URL) -> URL? {
//  // try to create it
//  do {
//    try FileManager().createDirectory( at: folderUrl, withIntermediateDirectories: true, attributes: nil)
//  } catch {
//    return nil
//  }
//  return folderUrl.appending(path: appName + ".log")
//}

/// Place log messages into the Log stream
/// - Parameters:
///   - msg: a text message
///   - level: the message level
///   - function: the function originating the entry
///   - file: the file originating the entry
///   - line: the line originating the entry
//public func log(_ msg: String, _ level: LogLevel, _ function: StaticString, _ file: StaticString, _ line: Int) {
//  _logStream( LogEntry(msg, level, function, file, line) )
//
//  switch level {
//    
//  case .debug:    XCGWrapper.log.debug(LogEntry(msg, level, function, file, line))
//  case .info:     XCGWrapper.log.info(LogEntry(msg, level, function, file, line))
//  case .warning:  XCGWrapper.log.warning(LogEntry(msg, level, function, file, line))
//  case .error:    XCGWrapper.log.error(LogEntry(msg, level, function, file, line))
//  }
//
//  if level == .warning || level == .error {
//    _logAlertStream(LogEntry(msg, level, function, file, line) )
//  }
//}

final public class XCGWrapper {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var shared = XCGWrapper()
  private init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var log: XCGLogger?
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
    
//  private var _cancellable: AnyCancellable?
//  private var _folderUrl: URL!

  private let kMaxLogFiles: UInt8  = 10
  private let kMaxTime: TimeInterval = 60 * 60 // 1 Hour
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
    
  public func setup(logLevel: XCGLogger.Level = .debug, group: String? = nil) {
    
    let info: (domain: String, appName: String) = {
      let bundleIdentifier = Bundle.main.bundleIdentifier!
      let separator = bundleIdentifier.lastIndex(of: ".")!
      let appName = String(bundleIdentifier.suffix(from: bundleIdentifier.index(separator, offsetBy: 1)))
      let domain = String(bundleIdentifier.prefix(upTo: separator))
      return (domain, appName)
    }()

    func setupLogFolder(_ info: (domain: String, appName: String), _ group: String?) -> URL? {
      var folderUrl: URL!

      if group == nil {
        // the app is using a normal Container
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        folderUrl = url.appending(path: "Logs")

      } else {
        // the app is using a Group Container
        let url = FileManager().containerURL(forSecurityApplicationGroupIdentifier: group!)
        folderUrl  = url?.appending(path: "Library/Application Support/Logs")
      }
      // try to create it
      do {
        try FileManager().createDirectory( at: folderUrl, withIntermediateDirectories: true, attributes: nil)
      } catch {
        return nil
      }
      return folderUrl.appending(path: info.appName + ".log")
    }
    
    log = XCGLogger(identifier: info.appName, includeDefaultDestinations: false)
    
#if DEBUG
    // for DEBUG only
    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: info.appName + ".systemDestination")
    
    // Optionally set some configuration options
    systemDestination.outputLevel           = logLevel
    systemDestination.showFileName          = false
    systemDestination.showFunctionName      = false
    systemDestination.showLevel             = true
    systemDestination.showLineNumber        = false
    systemDestination.showLogIdentifier     = false
    systemDestination.showThreadName        = false
    
    // Add the destination to the logger
    log!.add(destination: systemDestination)
#endif
    
    // Get / Create a file log destination
    if let logs = setupLogFolder(info, group) {
      let fileDestination = AutoRotatingFileDestination(writeToFile: logs,
                                                        identifier: info.appName + ".autoRotatingFileDestination",
                                                        shouldAppend: true,
                                                        appendMarker: "- - - - - App was restarted - - - - -")
      
      // Optionally set some configuration options
      fileDestination.outputLevel             = logLevel
      fileDestination.showDate                = true
      fileDestination.showFileName            = false
      fileDestination.showFunctionName        = false
      fileDestination.showLevel               = true
      fileDestination.showLineNumber          = false
      fileDestination.showLogIdentifier       = false
      fileDestination.showThreadName          = false
      fileDestination.targetMaxLogFiles       = kMaxLogFiles
      fileDestination.targetMaxTimeInterval   = kMaxTime
      
      // Process this destination in the background
      fileDestination.logQueue = XCGLogger.logQueue
      
      // Add the destination to the logger
      log!.add(destination: fileDestination)
      
      // Add basic app info, version info etc, to the start of the logs
      log!.logAppDetails()
      
      // format the date (only effects the file logging)
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
      dateFormatter.locale = Locale.current
      log!.dateFormatter = dateFormatter
      
//      // subscribe to Log requests
//      Task {
//        for await entry in logEntries {
//          // Log Handler to support XCGLogger
//          switch entry.level {
//            
//          case .debug:    log.debug(entry.msg)
//          case .info:     log.info(entry.msg)
//          case .warning:  log.warning(entry.msg)
//          case .error:    log.error(entry.msg)
//          }
//        }
//      }

    } else {
      fatalError("Logging failure:, unable to find / create Log folder")
    }
  }
}

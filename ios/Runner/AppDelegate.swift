import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Track scheduled auto-snooze tasks to cancel them when user takes action
  private var scheduledAutoSnoozes: [String: DispatchWorkItem] = [:]
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Configure UNUserNotificationCenter
    UNUserNotificationCenter.current().delegate = self
    
      // Set up method channel for sound management
      if let controller = window?.rootViewController as? FlutterViewController {
        let soundChannel = FlutterMethodChannel(
          name: "com.ios_alarm.sound",
          binaryMessenger: controller.binaryMessenger
        )
        
        soundChannel.setMethodCallHandler { (call, result) in
          switch call.method {
          case "playSound":
            if let soundName = call.arguments as? String {
              SoundManager.shared.playSound(named: soundName.replacingOccurrences(of: ".caf", with: ""))
              result(true)
            } else {
              result(FlutterError(code: "INVALID_ARGUMENT", message: "Sound name required", details: nil))
            }
          case "getAvailableSounds":
            result(SoundManager.getSoundFiles())
          case "cancelAutoSnooze":
            // Cancel auto-snooze for a specific reminder when user manually snoozes
            if let reminderId = call.arguments as? String {
              self.cancelAutoSnoozeForReminder(reminderId)
              result(true)
            } else {
              result(FlutterError(code: "INVALID_ARGUMENT", message: "Reminder ID required", details: nil))
            }
          default:
            result(FlutterMethodNotImplemented)
          }
        }
      }
    
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle significant time changes (clock adjustments, timezone changes)
  override func applicationSignificantTimeChange(_ application: UIApplication) {
    super.applicationSignificantTimeChange(application)
    
    // Notify Flutter about time change so it can reschedule notifications
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.ios_alarm.time_change",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("onSignificantTimeChange", arguments: nil)
    }
  }
  
  // Handle notification when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification even when app is in foreground with extended display time
    // Use .banner to ensure 15-second display duration (iOS 14+)
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
    
    // Using built-in notification sound with critical interruption level
    // to ensure banner stays visible longer and sound plays completely
    
    // Trigger auto-snooze for notifications that aren't auto-snooze themselves
    if let controller = window?.rootViewController as? FlutterViewController {
      let autoSnoozeChannel = FlutterMethodChannel(
        name: "com.ios_alarm.auto_snooze",
        binaryMessenger: controller.binaryMessenger
      )
      
      if let userInfo = notification.request.content.userInfo as? [String: Any],
         let isAutoSnooze = userInfo["isAutoSnooze"] as? Bool,
         let isTestNotification = userInfo["isTestNotification"] as? Bool,
         !isAutoSnooze && !isTestNotification {
        let notificationId = notification.request.identifier
        
        // Cancel any existing auto-snooze for this notification
        scheduledAutoSnoozes[notificationId]?.cancel()
        
        // Schedule auto-snooze after 1 minute if no action is taken
        let autoSnoozeTask = DispatchWorkItem {
          autoSnoozeChannel.invokeMethod("triggerAutoSnooze", arguments: [
            "notificationId": notificationId,
            "userInfo": userInfo
          ])
          // Remove from tracking once executed
          self.scheduledAutoSnoozes.removeValue(forKey: notificationId)
        }
        
        // Store the task so we can cancel it if user takes action
        scheduledAutoSnoozes[notificationId] = autoSnoozeTask
        
        // Execute after 1 minute
        DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: autoSnoozeTask)
      }
    }
  }
  
  // Handle notification response (taps and actions)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // Cancel any scheduled auto-snooze for this notification since user took action
    let notificationId = response.notification.request.identifier
    if let autoSnoozeTask = scheduledAutoSnoozes[notificationId] {
      autoSnoozeTask.cancel()
      scheduledAutoSnoozes.removeValue(forKey: notificationId)
      print("🚫 Cancelled auto-snooze for notification \(notificationId) due to user action")
    }
    
    // Sound is now handled by built-in notification system with critical interruption level
    
    // Let flutter_local_notifications handle the response
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
  
  // Helper function to extract sound name from notification
  private func extractSoundNameFromNotification(_ notification: UNNotification) -> String {
    // Try to get sound name from the notification's sound property
    if let sound = notification.request.content.sound {
      // For custom sounds, the sound will have a name
      if sound != UNNotificationSound.default {
        // Extract sound name - this is a simplified approach
        // The sound object doesn't directly expose the filename in iOS
        // So we'll use the subtitle as our primary method
      }
    }
    
    // Extract from subtitle or other indicators
    let subtitle = notification.request.content.subtitle ?? ""
    if subtitle.contains("🚨 ALARM") {
      return "alarm_1.caf"
    } else if subtitle.contains("🎵 CHIME") {
      return "chime_1.caf"
    } else if subtitle.contains("🔔 BELL") {
      return "bell_1.caf"
    }
    
    // Default fallback
    return "alarm_1.caf"
  }
  
  // Helper function to cancel auto-snooze for a specific reminder
  private func cancelAutoSnoozeForReminder(_ reminderId: String) {
    // Cancel any scheduled auto-snooze tasks for this reminder
    let keysToRemove = scheduledAutoSnoozes.keys.filter { key in
      key.contains(reminderId) || key.hasPrefix(reminderId)
    }
    
    for key in keysToRemove {
      scheduledAutoSnoozes[key]?.cancel()
      scheduledAutoSnoozes.removeValue(forKey: key)
      print("🚫 Cancelled auto-snooze task for reminder \(reminderId), key: \(key)")
    }
  }
}

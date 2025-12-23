import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Firebase and Supabase are initialized in Flutter main() function
    // No native initialization needed here
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

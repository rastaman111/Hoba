import UIKit
import GoogleMaps
import IQKeyboardManager
import YooKassaPayments
import YooKassaPaymentsApi
import UserNotifications
import YandexMobileMetrica
import YandexMobileMetricaPush
import SwiftyJSON
import Alamofire
import FirebaseCore
import FirebaseMessaging
import APESuperHUD
import Siren

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let googleApiKey = "AIzaSyBGSZTdOIvOQcHn3eKD17TKluCYedcVtxg"
    let appMetricaKey = "dd865a28-e968-42e0-a0a1-4570022aa3b1"
    let appMetricaPostKey = "e9b8206e-6119-4752-921c-47875e16e7ca"
    
    let hdr = [
        "X-AUTH-TOKEN": App.this.userToken
    ]
    
    var backgroundUpdateTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
    public static var localTime: Int = 0
    
    let notificationCenter = UNUserNotificationCenter.current()
    let notificationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
    
    func endBackgroundUpdateTask() {
        UIApplication.shared.endBackgroundTask(self.backgroundUpdateTask)
        self.backgroundUpdateTask = UIBackgroundTaskIdentifier.invalid
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        ///
        HUDAppearance.cancelableOnTouch = false
        
        ///
        URLSessionConfiguration.default.timeoutIntervalForRequest = 10
        URLSessionConfiguration.default.timeoutIntervalForResource = 10
        
        ///
        checkUpdates(completion: { _ in })
        checkNewVersion()

        ///
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        GMSServices.provideAPIKey(googleApiKey)
        
        ///
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().toolbarDoneBarButtonItemText = "Готово"
        IQKeyboardManager.shared().toolbarTintColor = UIColor(argb: 0xFF238fe8)
        
        ///
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: notificationOptions) {
            (didAllow, error) in
            if !didAllow {
                //print("--- User has declined notifications")
            }
        }
        
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                //print("--- Notifications not allowed")
            }
        }
        
        /// Yandex AppMetrica
        let configuration = YMMYandexMetricaConfiguration.init(apiKey: appMetricaKey)
        configuration?.logs = true
        YMMYandexMetrica.activate(with: configuration!)
        
        //
        YMPYandexMetricaPush.setExtensionAppGroup("EXTENSION_AND_APP_SHARED_APP_GROUP_NAME")
        let delegate = YMPYandexMetricaPush.userNotificationCenterDelegate()
        UNUserNotificationCenter.current().delegate = delegate
        YMPYandexMetricaPush.handleApplicationDidFinishLaunching(options: launchOptions)
        
        self.registerForPushNotificationsWithApplication(application)
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        //let params : [String : Any] = ["Закрытие": "true"]
        //YMMYandexMetrica.reportEvent("Закрытие", parameters: [:])
        
        YMMYandexMetrica.reportEvent("Закрытие", parameters: [:], onFailure: { (error) in
            //print("--- DID FAIL REPORT EVENT: %@")
            //print("--- REPORT ERROR: %@", error.localizedDescription)
        })
    }

    func registerForPushNotificationsWithApplication(_ application: UIApplication) {
        // Register for push notifications
        if #available(iOS 8.0, *) {
            if #available(iOS 10.0, *) {
                // iOS 10.0 and above
                let center = UNUserNotificationCenter.current()
                let category = UNNotificationCategory(identifier: "Custom category",
                                                      actions: [],
                                                      intentIdentifiers: [],
                                                      options:UNNotificationCategoryOptions.customDismissAction)
                // Only for push notifications of this category dismiss action will be tracked.
                center.setNotificationCategories(Set([category]))
                center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                    // Enable or disable features based on authorization.
                }
            } else {
                // iOS 8 and iOS 9
                let settings = UIUserNotificationSettings(types: [.badge, .alert, .sound], categories: nil)
                application.registerUserNotificationSettings(settings)
            }
            application.registerForRemoteNotifications()
        } else {
            // iOS 7
            application.registerForRemoteNotifications(matching: [.badge, .alert, .sound])
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        AppDelegate.localTime = Int(Date().localSeconds())
        self.backgroundUpdateTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.endBackgroundUpdateTask()
        })
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        AppDelegate.localTime = Int(Date().localSeconds())
        self.endBackgroundUpdateTask()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppDelegate.localTime = Int(Date().localSeconds())
    }
    
    ///
    func scheduleNotification(_ train: SingleTrain) {
        let content = UNMutableNotificationContent()
        content.title = "Через час начнется тренировка"
        content.body = "\(train.address), \(train.trainTime)"
        content.sound = UNNotificationSound.default
        content.badge = 0
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let fullDate = Date(timeIntervalSince1970: TimeInterval(train.startsAt - MIN_60))
        let triggerDate = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: fullDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let identifier = train.uid

        print("~~~ added ", identifier)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { (error) in
            if let error = error {
                print("!!! Error \(error.localizedDescription)")
            }
        }
    }
    
    func removeNotification(_ uid: String) {
        print("~~~ removed ", uid)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [uid])
        //notificationCenter.removeDeliveredNotifications(withIdentifiers: [uid])
    }
    
    func fireNotification(title: String, msg: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = msg
        content.sound = UNNotificationSound.default
        content.badge = 0

        ///
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "Workout Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
        notificationCenter.delegate = self
    }
    
    ///
    func checkNewVersion() {
        let siren = Siren.shared
        siren.presentationManager = PresentationManager(forceLanguageLocalization: .russian)
        siren.wail { results in
            switch results {
            //case .success(let updateResults):
                //print("--- AlertAction ", updateResults.alertAction)
                //print("--- Localization ", updateResults.localization)
                //print("--- Model ", updateResults.model)
                //print("--- UpdateType ", updateResults.updateType)
            //    break
            case .failure(let error):
                print(error.localizedDescription)
            default:
                break
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    //for displaying notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "Local Notification" {
            //print("--- Handling notifications with the Local Notification Identifier")
            print("~~~ Handling notifications with the Local Notification Identifier")
        }
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        ///print("--- Firebase registration token: \(fcmToken)")
        App.this.fcmToken = fcmToken!
        
        let dataDict:[String: String] = ["token": fcmToken!]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
    
    /*func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        //print("--- Received data message: \(remoteMessage.appData)")
    }*/
}

extension AppDelegate {
    func registerForPushNotifications(application: UIApplication) {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        let savedAPNSToken = UserDefaults.standard.object(forKey: "savedAPNSToken") as? String
        if savedAPNSToken != token {
            UserDefaults.standard.set(token, forKey: "savedAPNSToken")
            UserDefaults.standard.synchronize()
            Messaging.messaging().apnsToken = deviceToken
        }
        
        #if DEBUG
        let pushEnvironment = YMPYandexMetricaPushEnvironment.development
        #else
        let pushEnvironment = YMPYandexMetricaPushEnvironment.production
        #endif
        YMPYandexMetricaPush.setDeviceTokenFrom(deviceToken, pushEnvironment: pushEnvironment)
        
        //print("--- device token: ", token)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        //if let messageID = userInfo[gcmMessageIDKey] {
        //    print("Message ID: \(messageID)")
        //}
        
        // Print full message.
        //let userData = YMPYandexMetricaPush.userData(forNotification: userInfo)
    
        //print("--- 1 ", userInfo)
        self.handlePushNotification(userInfo)
    }
    
    /// APNs receiving data payload
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        //if let messageID = userInfo[gcmMessageIDKey] {
        //    print("Message ID: \(messageID)")
        //}
        
        // Print full message.
        //print("--- 2 ", userInfo)
        //let userData = YMPYandexMetricaPush.userData(forNotification: userInfo)
        

        self.handlePushNotification(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func handlePushNotification(_ userInfo: [AnyHashable : Any]) {
        // Track received remote notification.
        // Method [YMMYandexMetrica activateWithApiKey:] should be called before using this method.
        YMPYandexMetricaPush.handleRemoteNotification(userInfo)
    }
}

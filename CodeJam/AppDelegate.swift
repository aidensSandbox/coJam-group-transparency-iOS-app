/*-------------------------

  - BuzzIt -

  created by FV iMAGINATION © 2015
  All Rights reserved

-------------------------*/



import UIKit
import Parse
import ParseFacebookUtilsV4


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
 
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    
    // Init Parse
    let configuration = ParseClientConfiguration {
        $0.applicationId = PARSE_APP_KEY
        $0.clientKey = PARSE_CLIENT_KEY
        $0.server = "https://parseapi.back4app.com"
    }
    Parse.initialize(with: configuration)
    
    
    // Init Facebook Utils
    PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)

    // Live Query
    
    // User Status
    
    
    
    // REGISTER FOR PUSH NOTIFICATIONS
    let notifTypes:UIUserNotificationType  = [.alert, .badge, .sound]
    let settings = UIUserNotificationSettings(types: notifTypes, categories: nil)
    application.registerUserNotificationSettings(settings)
    application.registerForRemoteNotifications()
    application.applicationIconBadgeNumber = 0
    
    
    // ADD 3D-TOUCH SHORTCUT ACTIONS FOR HARD-PRESS ON THE APP ICON
    if #available(iOS 9.0, *) {
        let shortcut1 = UIMutableApplicationShortcutItem(type: "newroom",
                                                         localizedTitle: "New Room",
                                                         localizedSubtitle: "",
                                                         icon: UIApplicationShortcutIcon(templateImageName: "newRoomButt"),
                                                         userInfo: nil
        )
        
        let shortcut2 = UIMutableApplicationShortcutItem(type: "share",
                                                         localizedTitle: "Share BuzzIt",
                                                         localizedSubtitle: "",
                                                         icon: UIApplicationShortcutIcon(type: .share),
                                                         userInfo: nil
        )
        
        application.shortcutItems = [shortcut1, shortcut2]
        
    } else { /* Fallback on earlier versions */ }
    
    
    
return true
}

    
    
    
// HANDLER FOR 3D TOUCH ACTIONS
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        
        case "newroom" :
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let aVC = storyboard.instantiateViewController(withIdentifier: "NewRoom")
            window!.rootViewController?.present(aVC, animated: false, completion: nil)
            
        case "share" :
            let messageStr  = "Check out \(APP_NAME) and have fun!"
            let img = UIImage(named: "logo")!
            
            let shareItems = [messageStr, img] as [Any]
            
            let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            activityViewController.excludedActivityTypes = [.print, .postToWeibo, .copyToPasteboard, .addToReadingList, .postToVimeo]
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad
                let popOver = UIPopoverController(contentViewController: activityViewController)
                popOver.present(from: .zero, in: (window!.rootViewController?.view)!, permittedArrowDirections: .any, animated: true)
            } else {
                // iPhone
                window!.rootViewController?.present(activityViewController, animated: true, completion: nil)
            }

            
        default: break
        }
        completionHandler(true)
    }
    

    
    
    // MARK: - DELEGATES FOR PUSH NOTIFICATIONS
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let installation = PFInstallation.current()
        installation?.setDeviceTokenFrom(deviceToken)
        installation?.saveInBackground(block: { (succ, error) in
            if error == nil {
                print("DEVICE TOKEN REGISTERED! ---")
            } else {
                print("\(error!.localizedDescription)")
            }
        })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        PFPush.handle(userInfo)
        if application.applicationState == .inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(inBackground: userInfo, block: nil)
        }
    }
    
    
    
    
    
    // MARK: - DELEGATES FOR FACEBOOK LOGIN
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {

        FBSDKAppEvents.activateApp()

        let installation = PFInstallation.current()
        print("BADGE: \(installation!.badge)")
        if installation?.badge != 0 {
            installation?.badge = 0
            installation?.saveInBackground(block: { (succ, error) in
                if error == nil {
                    print("Badge reset to 0")
                } else {
                    print("\(error!.localizedDescription)")
                }})
        }
    }

    
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


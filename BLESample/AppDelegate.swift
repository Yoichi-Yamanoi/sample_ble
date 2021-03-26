//
//  AppDelegate.swift
//  BLESample
//
//  Created by Yoichi_Yamanoi on 2020/04/13.
//  Copyright © 2020 Sample. All rights reserved.
//

import UIKit
import Intents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
//        if #available(iOS 12.0, *) {
//            if userActivity.activityType == String(describing: OpenDoorIntent.self) {
//                guard let _ = userActivity.interaction?.intent as? OpenDoorIntent else {
//                    return false
//                }
//                //　ドアをあける
//                BLEHelper.shared.connectOpenDoor()
//                return true
//            } else {
//                // Fallback on earlier versions
//            }
//        }
        return false
    }
}

extension AppDelegate {

    /// AppDelegateのシングルトン
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    /// rootViewControllerは常にRootVC
    var rootVC: UIViewController {
        return window!.rootViewController!
    }
}

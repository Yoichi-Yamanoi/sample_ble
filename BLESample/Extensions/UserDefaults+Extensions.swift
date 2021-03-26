//
//  UserDefaults+Extensions.swift
//  BLESample
//
//  Created by Yoichi_Yamanoi on 2020/04/13.
//  Copyright © 2020 Sample. All rights reserved.
//

import UIKit

extension UserDefaults {
    enum Key: String {
        case deviceMode
        case bleReceiverId
    }
    
    class func setValue(_ value: Any?, forKey key: Key) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(value, forKey: key.rawValue)
        userDefaults.synchronize()
    }
    
    class func getValue(_ key: Key) -> Any? {
        let userDefaults = UserDefaults.standard
        return userDefaults.object(forKey: key.rawValue)
    }
    
    class func remove(_ key: Key) {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: key.rawValue)
    }
}

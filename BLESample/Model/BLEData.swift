//
//  BLEData.swift
//  BLESample
//
//  Created by Yoichi_Yamanoi on 2020/04/20.
//  Copyright © 2020 Sample. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreMotion

// MARK: - BLEData

enum BLECommand: String {
    case openDoor
    case closeDoor
}

struct BLEData {
    var messageLengthOfBytes: UInt8
    var message: String
    
    private init(message: String) {
        self.messageLengthOfBytes = UInt8(message.lengthOfBytes(using: .utf8))
        self.message = message
    }
    
    init() {
        self.messageLengthOfBytes = 0
        self.message = ""
    }
    
    init(command: BLECommand) {
        self.init(message: command.rawValue)
    }

    init(bytes: Data) {
        self.messageLengthOfBytes = Data(bytes[0..<1]).to(type: UInt8.self)
        if bytes.count >= messageLengthOfBytes + 1 {
            self.message = String(bytes: Data(bytes[1..<1+messageLengthOfBytes]), encoding: .utf8) ?? ""
        } else {
            self.message = ""
        }
    }

    var data: Data {
        var data = Data()
        data.append(messageLengthOfBytes.bytes)
        if let messageBytes = message.bytes {
            data.append(messageBytes)
        }
        return data
    }    
}

extension UInt8 {
    var bytes: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt8>.size)        
    }
}

extension String {
    var bytes: Data? {
        return data(using: .utf8)
    }
}

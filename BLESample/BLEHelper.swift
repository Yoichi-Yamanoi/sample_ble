//
//  BLEHelper.swift
//  BLESample
//
//  Created by Yoichi_Yamanoi on 2020/04/13.
//  Copyright © 2020 Sample. All rights reserved.
//

import Foundation
import CoreBluetooth
import CryptoSwift

// MARK: - Connection Helper
// Central
class BLEHelper: NSObject {
    static let shared = BLEHelper()
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?

    var action: ((BLEData) -> Void)?
    var completion: (() -> Void)?
    var uuid: UUID?

    override private init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /// 接続（送信側)
    func connect(identifier: String, action: ((BLEData) -> Void)?) {
        self.uuid = UUID(uuidString: identifier)
        self.action = action
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func connectOpenDoor() {
        guard let uuid = UserDefaults.getValue(.bleReceiverId) as? String,
            !uuid.isEmpty else {
                return
        }
        completion = {
            DispatchQueue.main.async { [weak self] in
                self?.write(command: .openDoor)
            }
        }
        connect(identifier: uuid, action: nil)
    }

    /// 接続中止（送信側)
    func cancel() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
    
    func write(command: BLECommand) {
        if let aCharacteristic = characteristic {
            peripheral?.writeValue(BLEData(command: command).data, for: aCharacteristic, type: .withResponse)
        }
    }

    /// 暗号処理
    static func encrypt(_ data: Data) -> Data? {
        do {
            let blockMode = CTR(iv: Constants.BLE.iv)
            let aes = try AES(key: Constants.BLE.encryptkey, blockMode: blockMode, padding: .noPadding)
            let cipherArray = try aes.encrypt(data.bytes)
            let encryptData = Data(bytes: cipherArray, count: cipherArray.count)
            return encryptData
        } catch {
            return nil
        }
    }

    /// 復号処理
    static func decrypt(_ encryptData: Data) -> Data? {
        do {
            // AES インスタンス化
            let blockMode = CTR(iv: Constants.BLE.iv)
            let aes = try AES(key: Constants.BLE.encryptkey, blockMode: blockMode)
            // UInt8 配列の作成
            let aBuffer = Array<UInt8>(encryptData)
            // AES 複合
            let decrypted = try aes.decrypt(aBuffer)
            return Data(decrypted)
        } catch {
            // エラー処理
            return nil
        }
    }
}

extension BLEHelper: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String, name.lowercased().contains("ble") {
            if peripheral.identifier == uuid {
                self.peripheral = peripheral
                centralManager.connect(peripheral, options: nil)
                
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    }
}

// MARK: - CBPeripheralDelegate

extension BLEHelper: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services, !services.isEmpty else { return }
        for service in services {
            if service.uuid == Constants.BLE.serviceUUID {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics, !characteristics.isEmpty else { return }
        for characteristic in characteristics {
            if Constants.BLE.Characteristic.uuids.contains(characteristic.uuid) {
                self.characteristic = characteristic
                self.completion?()
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else {
            return
        }
        if Constants.BLE.Characteristic.uuids.contains(characteristic.uuid) {
            let data = BLEData(bytes: data)
            self.action?(data)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
    }
}

// MARK: - Extensions

extension Data {
    func to<T>(type: T.Type) -> T {
        return withUnsafeBytes { $0.load(as: T.self) }
    }
}

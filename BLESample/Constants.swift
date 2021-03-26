//
//  Constants.swift
//  BLESample
//
//  Created by Yoichi_Yamanoi on 2020/09/29.
//  Copyright © 2020 Sample. All rights reserved.
//

import UIKit
import CoreBluetooth

struct Constants {
    /// アプリのバージョン
    static let appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    /// サイドメニューの幅
    static let sideMenuWidth: CGFloat = 280
    /// URL
    struct URL {
        /// URL: 利用規約
        static let termOfUse = "https://twitter.com/home"
        /// URL: スキャン詳細説明
        static let scanDescription = "https://twitter.com/home"
        /// URL: アプリの使い方説明
        static let appGuide = "https://www.google.co.jp/"
        /// URL: お客様サポートセンター
        static let customerSupport = "https://www.google.co.jp/"
    }

    /** 下記の参照資料が変わったら更新
     Doac BLE通信仕様_20200609.xlsx
     */
    struct BLE {
        /// サービスUUID
        static let serviceUUID: CBUUID = CBUUID(string: "b1ca3194-98c5-11ea-bb37-0242ac130002")
        /// スキャン時間
        static let scanTime: Double = 30 // seconds
        /// 再接続時間
        static let retriveTime: Double = 30 // seconds
        /// 暗号化キー（128bit/16byte)
        // TODO: ハードコーディングNG(サンプル）
        static let encryptkey: Array<UInt8> = [0x19, 0x0d, 0x1a, 0x9d,
                                               0x29, 0x99, 0xef, 0x64,
                                               0x41, 0xc3, 0xa3, 0x70,
                                               0x23, 0x40, 0xa3, 0xb9]
        /// 初期ベクトル(128bit/16byte)
        // TODO: ハードコーディングNG(サンプル）
        static let iv: Array<UInt8> = [0x2b, 0x7e, 0x15, 0x16,
                                       0x28, 0xae, 0xd2, 0xa6,
                                       0xab, 0xf7, 0x15, 0x88,
                                       0x09, 0xcf, 0x4f, 0x3c]
        // DateFormatter("yyyyMMddHHmmss")
        static let dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmmss"
            return dateFormatter
        }()
        /// ペリフェラル端末名
        static var peripheralName: String {
            get {
                return UserDefaults.standard.object(forKey: "peripheralName") as? String ?? "ML_BLESample(iOS)"
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "peripheralName")
                UserDefaults.standard.synchronize()
            }
        }
        /// キャラクタリスティックUUID
        enum Characteristic: String, CaseIterable {
            /// キー登録
            case registerKey = "965b093a-98c8-11ea-bb37-0242ac130002"
            /// キー登録結果要求
            case registerKeyResult = "965b0cc8-98c8-11ea-bb37-0242ac130002"
            /// 施錠/解錠要求
            case openOrClose = "965b0db8-98c8-11ea-bb37-0242ac130002"
            /// 施錠/解錠結果要求
            case openOrCloseResult = "965b0e8a-98c8-11ea-bb37-0242ac130002"
            /// 新規登録キー確認
            case confirmNewKey = "965b0f52-98c8-11ea-bb37-0242ac130002"
            /// キー情報消去
            case deleteKey = "965b101a-98c8-11ea-bb37-0242ac130002"

            /// uuid
            var uuid: CBUUID {
                return CBUUID(string: self.rawValue)
            }

            static var uuids: [CBUUID] {
                return allCases.map { $0.uuid }
            }

            static func get(_ uuid: CBUUID) -> Characteristic? {
                for characteristic in Characteristic.allCases where characteristic.uuid == uuid {
                    return characteristic
                }
                return nil
            }

            var characteristic: CBMutableCharacteristic {
                switch self {
                case .registerKey, .openOrClose:
                    return CBMutableCharacteristic(
                        type: uuid,
                        properties: [.writeWithoutResponse],
                        value: nil,
                        permissions: [.writeable, .writeEncryptionRequired]
                    )
                case .registerKeyResult, .openOrCloseResult, .confirmNewKey:
                    return CBMutableCharacteristic(
                        type: uuid,
                        properties: [.read],
                        value: nil,
                        permissions: [.readEncryptionRequired]
                    )
                case .deleteKey:
                    return CBMutableCharacteristic(
                        type: uuid,
                        properties: [.write],
                        value: nil,
                        permissions: [.writeable, .writeEncryptionRequired]
                    )
                }
            }

            static var characteristics: [CBCharacteristic] {
                return allCases.map { $0.characteristic }
            }
        }
    }
}

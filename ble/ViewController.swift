//
//  ViewController.swift
//  ble
//
//  Created by IshimotoKiko on 2017/07/05.
//  Copyright © 2017年 IshimotoKiko. All rights reserved.
//

import Cocoa
import CoreBluetooth
class ViewController: NSViewController,CBCentralManagerDelegate, CBPeripheralDelegate  {
    var isScanning: Bool = false
    var isBlink: Bool = false
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var settingCharacteristic: CBCharacteristic!
    var outputCharacteristic: CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // ===============================================================================
    // MARK: Actions
    
    // スキャン
    @IBAction func btn1(_ sender: NSButton) {
        if !isScanning {
            isScanning = true
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            sender.title = "Stop Scan";
        }
        else {
            isScanning = false
            self.centralManager.stopScan()
            sender.title = "Start Scan";
        }
    }
    
    
    // LEDスイッチ
    @IBAction func btn2(_ sender: Any) {
        if self.settingCharacteristic == nil || self.outputCharacteristic == nil {
            print("konashi is not ready!")
            return
        }
        var value: CUnsignedChar
        
        if !isBlink {
            isBlink = true
            // LED2を光らせる
            value = 0x01 << 1
            
        }
        else {
            isBlink = false
            // LED2を消す
            value = 0x00 << 1
        }
        let data: NSData = NSData(bytes: &value, length: 1)
        
        
        self.peripheral.writeValue(data as Data,
                                   for: self.settingCharacteristic,
                                   type: CBCharacteristicWriteType.withoutResponse)
        
        self.peripheral.writeValue(data as Data,
                                   for: self.outputCharacteristic,
                                   type: CBCharacteristicWriteType.withoutResponse)
    }
    
    // ===============================================================================
    // MARK: CBCentral Manager Delegate
    
    // セントラルマネージャの状態変化があると呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state)")
    }
    
    // ペリフェラルが見つかると呼ばれる
    private func centralManager(central: CBCentralManager,
                        didDiscoverPeripheral peripheral: CBPeripheral,
                        advertisementData: [String : AnyObject],
                        RSSI: NSNumber)
    {
        print("発見したBLEデバイス: \(peripheral)\n")
        
        if peripheral.name?.hasPrefix("konashi") == true {
            self.peripheral = peripheral
            // 接続開始
            self.centralManager.connect(self.peripheral, options: nil)
        }
        
    }
    
    // ペリフェラルに接続したら呼ばれる
    func centralManager(central: CBCentralManager,
                        didConnectPeripheral peripheral: CBPeripheral)
    {
        print("接続成功")
        
        // サービス検索結果を受け取るデリゲートをセット
        peripheral.delegate = self
        // サービス検索開始
        peripheral.discoverServices(nil)
    }
    
    // ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?)
    {
        print("接続失敗...")
    }
    
    // ===============================================================================
    // MARK: CBPeripheralDelegate
    
    // サービス発見したら呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil {
            print("エラー: " + (error.debugDescription))
            return
        }
        
        if (peripheral.services?.count)! <= 0 {
            print("no services")
            return
        }
        
        let services = peripheral.services!
        print("\(services.count)個のサービスを発見しました。\n\(services)\n")
        
        for service in services {
            peripheral.discoverCharacteristics(nil , for: service)
        }
        
    }
    
    // キャラクタリスティックを取得したら呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?)
    {
        if error != nil {
            print("エラー: " + error.debugDescription)
            return
        }
        
        if (service.characteristics?.count)! <= 0 {
            print("no characteristics")
            return
        }
        
        let characteristics = service.characteristics!
        print("\(characteristics.count)個のキャラクタリスティックを発見しました。\n\(characteristics)\n")
        
        for characteristic in characteristics {
            
            if characteristic.uuid.isEqual(CBUUID(string: "229B3000-03FB-40DA-98A7-B0DEF65C2D4B")) {
                self.settingCharacteristic = characteristic
                print("KONASHI_PIO_SETTING_UUID を発見")
            } else if characteristic.uuid.isEqual(CBUUID(string: "229B3002-03FB-40DA-98A7-B0DEF65C2D4B")) {
                self.outputCharacteristic = characteristic
                print("KONASHI_PIO_OUTPUT_UUID を発見")
            }
        }
    }
    

}


//
//  ViewController.m
//  BLECentralSample
//
//  Created by Takahiro Kato on 2014/11/02.
//  Copyright (c) 2014年 grandbig.github.io. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "NSData+Conversion.h"
#import "NSString+Conversion.h"

@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) CBCentralManager *cm;
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;
@property (weak, nonatomic) IBOutlet UITableView *tv;
@property (strong, nonatomic) NSMutableArray *advArray, *peripheralArray, *charKeyArray, *charValueArray;
@property (strong, nonatomic) CBCharacteristic *majorChar;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // CBCentralManagerの初期化
    self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    // UITableViewのDelegateを設定
    self.tv.delegate = self;
    self.tv.dataSource = self;
    
    self.advArray = [[NSMutableArray alloc] init];
    self.peripheralArray = [[NSMutableArray alloc] init];
    self.charKeyArray = [[NSMutableArray alloc] init];
    self.charValueArray = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if(central.state == CBCentralManagerStatePoweredOn) {
        // スキャンの開始
        [self.cm scanForPeripheralsWithServices:nil options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // advertisementDataの中身を確認
    // 下記は指定可能な全てのkey
    NSString *localNameData = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    NSString *manufacturerData = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
    NSString *serviceData = [advertisementData objectForKey:CBAdvertisementDataServiceDataKey];
    NSString *UUIDData = [advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey];
    NSString *overflowServiceUUIDData = [advertisementData objectForKey:CBAdvertisementDataOverflowServiceUUIDsKey];
    NSString *txPowerLevelData = [advertisementData objectForKey:CBAdvertisementDataTxPowerLevelKey];
    NSString *isConnectableData = [advertisementData objectForKey:CBAdvertisementDataIsConnectable];
    NSString *solicitedServiceUUIDData = [advertisementData objectForKey:CBAdvertisementDataSolicitedServiceUUIDsKey];
    
    NSLog(@"localName: %@\n, manufacturerData: %@\n, serviceData: %@\n, serviceUUID: %@\n, overflowServiceUUID: %@\n, txPowerLevel: %@, isConnectable: %@\n, solicitedServiceUUID: %@", localNameData, manufacturerData, serviceData, UUIDData, overflowServiceUUIDData, txPowerLevelData, isConnectableData, solicitedServiceUUIDData);
    
    NSLog(@"%@", RSSI);
    NSLog(@"%@", advertisementData);
    
    [self.advArray addObject:localNameData];
    [self.tv reloadData];
    
    [self.peripheralArray addObject:peripheral];
}

// Peripheralとの接続に失敗した場合に呼び出される処理
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
}

// Peripheralと接続できた場合に呼び出される処理
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // スキャンの停止
    [self.cm stopScan];
    
    // Peripheralのサービスを検索
    [self.connectedPeripheral discoverServices:nil];
}

// Peripheralから切断されたときに呼び出される処理
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if(error) {
        return;
    }
    
    for(CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:@"27210D78-F238-45D5-9DC9-87FE9C6671E2"]] forService:service];
    }
}

#pragma mark - CBPeripheralDelegate
// Servicesが見つかったときに呼び出される処理
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSArray *services = peripheral.services;
    NSLog(@"%@", services);
    
    for (CBService *service in services) {
        NSLog(@"Service UUID: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// Characteristicesが見つかったときに呼び出される処理
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if(error) {
        return;
    }
    
    for(CBCharacteristic *characteristic in service.characteristics) {
        // keyを配列に保存
        CBUUID *uuid = characteristic.UUID;
        NSString *uuidString = [[NSString alloc] initWithFormat:@"%@", uuid];
        [self.charKeyArray addObject:uuidString];
        
        if([uuidString isEqual:@"569A2013-B87F-490C-92CB-11BA5EA5167C"]) {
            // major値の場合はCharacteristicをメモリに保持
            self.majorChar = characteristic;
        }
        
        // propertiesを取得
        CBCharacteristicProperties properties = characteristic.properties;
        
        // 値が変わったときに通知を受けたい場合に設定
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        // Characteristicの値を読み込む
        [peripheral readValueForCharacteristic:characteristic];
    }
}

//  Characteristicsの値が取得できたときに呼び出される処理
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error) {
        NSLog(@"error: %@", error);
        return;
    }
    
    NSLog(@"value: %@", characteristic.value);
    NSUInteger index;
    [characteristic.value getBytes:&index length:sizeof(index)];
    NSLog(@"%ld", (long)index);
    
    
    NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    if(!value) {
        value = @"";
    }
    [self.charValueArray addObject:value];
    //NSLog(@"%@", value);
}

// Characteristicの書き込み処理が完了した場合に呼び出される処理
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error) {
        NSLog(@"error: %@", error);
        return;
    }
}

#pragma mark - UITableViewDelegate
// セクションに対する行を返却
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger advCnt = self.advArray.count;
    return advCnt;
}

// cellの作成
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [[UITableViewCell alloc] init];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [self.advArray objectAtIndex: indexPath.row];
    
    return cell;
}

// セルが選択されたときに呼び出されるメソッド
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // 選択したPeripheralのオブジェクトを取得
    CBPeripheral *peripheral = [self.peripheralArray objectAtIndex:indexPath.row];
    
    self.connectedPeripheral = peripheral;
    self.connectedPeripheral.delegate = self;
    
    // Peripheralへの接続処理
    [self.cm connectPeripheral:self.connectedPeripheral options:nil];
    
    // セルの選択状態を解除
    [self.tv deselectRowAtIndexPath:[self.tv indexPathForSelectedRow] animated:NO];
}

// 書き込みテスト用のメソッド
- (IBAction)writeDataTestMethod:(id)sender {
    NSInteger writeInt = 4661;
    NSString *witeString = [NSString stringWithFormat:@"%lX",(long)writeInt];
    NSData *writeData = [witeString dataFromHexString];
    NSLog(@"writeData: %@", writeData);
    
    [self.connectedPeripheral writeValue:writeData forCharacteristic:self.majorChar type:CBCharacteristicWriteWithResponse];
}
@end

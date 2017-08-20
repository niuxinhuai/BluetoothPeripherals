//
//  ViewController.m
//  BlueToochAnother
//
//  Created by 牛新怀 on 2017/8/19.
//  Copyright © 2017年 牛新怀. All rights reserved.
//
#define SERVICE_UUID @"CDD1"
#define CHARACTERISTIC_UUID @"CDD2"
#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
@interface ViewController ()<CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager * peripheralManager;
@property (nonatomic, strong) CBMutableCharacteristic    * characteristic;
@property (nonatomic, strong) UITextField         * my_textField;
@property (nonatomic, strong) UIButton            * senderButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // 创建外设管理器，会回调peripheralManagerDidUpdateState方法
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    [self.view addSubview:self.my_textField];
    [self.view addSubview:self.senderButton];

}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}
- (void)sendAnithingWithDate{
    // 发送数据
    BOOL sendSuccess = [self.peripheralManager updateValue:[self.my_textField.text dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
    if (sendSuccess) {
        NSLog(@"数据发送成功");
    }else {
        NSLog(@"数据发送失败");
    }
    

}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBManagerStatePoweredOn) {
        // 创建Service（服务）和Characteristics（特征）
        [self setupServiceAndCharacteristics];
        // 根据服务的UUID开始广播
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:SERVICE_UUID]]}];
    }

    
}
/** 创建服务和特征 */
- (void)setupServiceAndCharacteristics {
    /*
     注意CBCharacteristicPropertyNotify这个参数，只有设置了这个参数，在中心设备中才能订阅这个特征。
     一般开发中可以设置两个特征，一个用来发送数据，一个用来接收中心设备写过来的数据，我们这里为了方便就只设置了一个特征。
     最后用一个属性拿到这个特征，是为了后面单独发送数据的时候使用，数据的写入和读取最终还是要通过特征来完成。

     */
    
    
    // 创建服务
    CBUUID *serviceID = [CBUUID UUIDWithString:SERVICE_UUID];
    CBMutableService *service = [[CBMutableService alloc] initWithType:serviceID primary:YES];
    // 创建服务中的特征
    CBUUID *characteristicID = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
    CBMutableCharacteristic *characteristic = [
                                               [CBMutableCharacteristic alloc]
                                               initWithType:characteristicID
                                               properties:
                                               CBCharacteristicPropertyRead |
                                               CBCharacteristicPropertyWrite |
                                               CBCharacteristicPropertyNotify
                                               value:nil
                                               permissions:CBAttributePermissionsReadable |
                                               CBAttributePermissionsWriteable
                                               ];
    // 特征添加进服务
    service.characteristics = @[characteristic];
    // 服务加入管理
    [self.peripheralManager addService:service];
    
    // 为了手动给中心设备发送数据
    self.characteristic = characteristic;
}

/** 中心设备读取数据的时候回调 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    // 请求中的数据，这里把文本框中的数据发给中心设备
    request.value = [self.my_textField.text dataUsingEncoding:NSUTF8StringEncoding];
    // 成功响应请求
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

/** 中心设备写入数据的时候回调 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    // 写入数据的请求
    CBATTRequest *request = requests.lastObject;
    // 把写入的数据显示在文本框中
    self.my_textField.text = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
}


/** 订阅成功回调 */
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"订阅成功: %s",__FUNCTION__);
}

/** 取消订阅回调 */
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"取消订阅: %s",__FUNCTION__);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (UITextField *)my_textField{
    if (!_my_textField) {
        _my_textField = [[UITextField alloc]init];
        _my_textField.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2-80);
        _my_textField.bounds = CGRectMake(0, 0, 200, 50);
        [_my_textField setBorderStyle:UITextBorderStyleLine];
        
    }
    return _my_textField;
    
}

- (UIButton *)senderButton{
    if (!_senderButton) {
        _senderButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _senderButton.center = CGPointMake(self.my_textField.center.x, CGRectGetMaxY(self.my_textField.frame)+50);
        _senderButton.bounds = CGRectMake(0, 0, 100, 30);
        [_senderButton setTitle:@"发送数据" forState:0];
        [_senderButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_senderButton addTarget:self action:@selector(sendAnithingWithDate) forControlEvents:UIControlEventTouchUpInside];
    }
    return _senderButton;
}

@end

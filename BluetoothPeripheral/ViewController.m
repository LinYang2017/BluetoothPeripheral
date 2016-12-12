#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#define kPeripheralName @"Lin's Device"                                 //The Name of Peripheral
#define kServiceUUID @"C4FB2349-72FE-4CA2-94D6-1F3CB16331EE"            //Service UUID
#define kCharacteristicUUID @"6A3E4B28-522D-4B3B-82A9-D5E2004534FC"     //Characteristic UUID

@interface ViewController ()

@property (strong,nonatomic) CBPeripheralManager *peripheralManager;    //Peripheral Manager

@property (strong,nonatomic) NSMutableArray *centralM;                  //Central Manager
@property (strong,nonatomic) CBMutableCharacteristic *characteristicM;  //Characteristic
@property (weak) IBOutlet NSTextField *log;

@end





@implementation ViewController


#pragma mark - UI Controller
- (void)viewDidLoad {
    [super viewDidLoad];
}



#pragma mark - UI Event
//Create peripheral manager
- (IBAction)startClick:(NSButtonCell *)sender {
    _peripheralManager=[[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}


//Upadate characteristic value
- (IBAction)updateClick:(NSButton *)sender {
    [self updateCharacteristicValue];
}



#pragma mark - CBPeripheralManager delegate
//if the state of peripheral changed, the method will be involved.
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"BLE opened.");
            [self writeToLog:@"BLE opened."];
            
            //Add Service
            [self setupService];
            break;
            
        default:
            NSLog(@"This device doesn't support BLE or bluetooth doesn't open.");
            [self writeToLog:@"This device doesn't support BLE or bluetooth doesn't open."];
            break;
    }
}


//The method will be involved after add peripheral.
-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    if (error) {
        NSLog(@"Failed to add service to peripheral. Error info：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"Failed to add service to peripheral. Error info：：%@",error.localizedDescription]];
        return;
    }
    
    //if the service has been added successfully, begin to broadcast.
    NSDictionary *dic=@{CBAdvertisementDataLocalNameKey:kPeripheralName};//Settings of broadcast
    [self.peripheralManager startAdvertising:dic];//broadcast.
    NSLog(@"Add service to peripheral. Begin to broadcast...");
    [self writeToLog:@"Add service to peripheral. Begin to broadcast..."];
}




-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    if (error) {
        NSLog(@"There is an error during broadcasting，Error info：%@",error.localizedDescription);
        [self writeToLog:[NSString stringWithFormat:@"There is an error during broadcasting，Error info：%@",error.localizedDescription]];
        return;
    }
    NSLog(@"Begin to broadcast...");
    [self writeToLog:@"Begin to broadcast..."];
}



//Rigester characteristic
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"Central：%@ the characteristic：%@.",central,characteristic);
    [self writeToLog:[NSString stringWithFormat:@"Central：%@ the characteristic：%@.",central.identifier.UUIDString,characteristic.UUID]];
    
    //find central device and save it
    if (![self.centralM containsObject:central]) {
        [self.centralM addObject:central];
    }
    /*//update characteristic
     -(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
     */
    
    //    [self updateCharacteristicValue];
}


//Cannel characteristic
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"didUnsubscribeFromCharacteristic");
}
-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(CBATTRequest *)request{
    NSLog(@"didReceiveWriteRequests");
}
-(void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict{
    NSLog(@"willRestoreState");
}


#pragma mark -Properities
-(NSMutableArray *)centralM{
    if (!_centralM) {
        _centralM=[NSMutableArray array];
    }
    return _centralM;
}

#pragma mark - Private methods
//Set up characteristic and service. Add service to peripheral
-(void)setupService{
    /*1.Set up characteristic*/
    //set up UUID
    CBUUID *characteristicUUID=[CBUUID UUIDWithString:kCharacteristicUUID];
    //the value of 
    //    NSString *valueStr=kPeripheralName;
    //    NSData *value=[valueStr dataUsingEncoding:NSUTF8StringEncoding];
    //Creat Charateristic
    /** Properties
     * uuid:Charateristic uuid
     * properties:Charateristic properties
     * value:Charateristic value
     * permissions:Charateristic permissions
     */
    CBMutableCharacteristic *characteristicM=[[CBMutableCharacteristic alloc]initWithType:characteristicUUID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    self.characteristicM=characteristicM;
    //    CBMutableCharacteristic *characteristicM=[[CBMutableCharacteristic alloc]initWithType:characteristicUUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    //    characteristicM.value=value;
    
    /*Set up Service and Service's charateristic*/
    //Set up uuid
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    //Set up service
    CBMutableService *serviceM=[[CBMutableService alloc]initWithType:serviceUUID primary:YES];
    //Set up characteristic
    [serviceM setCharacteristics:@[characteristicM]];
    
    
    /*add service to peripheral*/
    [self.peripheralManager addService:serviceM];
}



//Update Characteristic's value
-(void)updateCharacteristicValue{
    //set characteristic
    NSString *valueStr=[NSString stringWithFormat:@"%@ --%@",kPeripheralName,[NSDate   date]];
    NSData *value=[valueStr dataUsingEncoding:NSUTF8StringEncoding];
    //update characteristic
    [self.peripheralManager updateValue:value forCharacteristic:self.characteristicM onSubscribedCentrals:nil];
    [self writeToLog:[NSString stringWithFormat:@"Update Characteristic：%@",valueStr]];
}
/**
 *  Record Log
 *
 *  @param info log information
 */
-(void)writeToLog:(NSString *)info{
    self.log.stringValue=[NSString stringWithFormat:@"%@\r\n%@",self.log.stringValue,info];

}
@end

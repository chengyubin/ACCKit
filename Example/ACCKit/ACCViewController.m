//
//  ACCViewController.m
//  ACCKit
//
//  Created by chengyb on 01/25/2021.
//  Copyright (c) 2021 chengyb. All rights reserved.
//

#import "ACCViewController.h"
#import <ACCKit/ACCKit.h>

@interface ACCViewController ()
@property (nonatomic, strong) ACCSensorMonitor *sensorMonitor;

@end

@implementation ACCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Begin Monitor");
    // Do any additional setup after loading the view, typically from a nib.
    [self.sensorMonitor startProximityMonitor:^(BOOL state) {
        NSLog(@"ProximityMonitor: %@", state?@"靠近":@"远离");
    }];
    [self.sensorMonitor startBatteryMonitor:^(UIDeviceBatteryState state, float batteryLevel) {
        NSString *stateStr = @"未知";
        switch (state) {
            case UIDeviceBatteryStateUnplugged:
                stateStr = @"未充电";
                break;
            case UIDeviceBatteryStateCharging:
                stateStr = @"充电中";
                break;
            case UIDeviceBatteryStateFull:
                stateStr = @"充满电";
                break;
            default:
                break;
        }
        NSLog(@"BatteryMonitor: %@, %@%%", stateStr, @(batteryLevel*100));
    }];
    
    [self.sensorMonitor startAccelerometerMonitor:^(CMAcceleration acceleration, NSError * _Nullable error) {
        NSLog(@"AccelerometerMonitor: x:%lf, y:%lf, z:%lf", acceleration.x, acceleration.y, acceleration.z);
    }];
    
    [self.sensorMonitor startGyroMonitor:^(CMRotationRate rotationRate, NSError * _Nullable error) {
        NSLog(@"GyroMonitor: x:%lf, y:%lf, z:%lf", rotationRate.x, rotationRate.y, rotationRate.z);
    }];
    
    [self.sensorMonitor startMagnetometerMonitor:^(CMMagneticField magneticField, NSError * _Nullable error) {
        NSLog(@"MagnetometerMonitor: x:%lf, y:%lf, z:%lf", magneticField.x, magneticField.y, magneticField.z);
    }];
    
    [self.sensorMonitor startDeviceMotionMonitor:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        NSLog(@"\n==================================\nDeviceMotionMonitor: %@\n", motion);
    }];
    
//    [self.sensorMonitor startLocationMonitor:^(CLLocation * _Nonnull location, NSError * _Nullable error) {
//        NSLog(@"%@, %@", location, error);
//    }];
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.sensorMonitor stopLocationMonitor];
//    });

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ACCSensorMonitor *)sensorMonitor{
    if (!_sensorMonitor) {
        _sensorMonitor = [ACCSensorMonitor new];
    }
    return _sensorMonitor;
}
@end

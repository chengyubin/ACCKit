//
//  ACCSensorMonitor.m
//  ACCKit
//
//  Created by CCyber on 2021/1/15.
//

#import "ACCSensorMonitor.h"
#import "ACCTimerManager.h"
@interface ACCSensorMonitor()<CLLocationManagerDelegate>
@property (nonatomic, strong) void (^proximityMonitor)(BOOL state);
@property (nonatomic, strong) void (^batteryMonitor)(UIDeviceBatteryState state, float batteryLevel);
@property (nonatomic, strong) void (^locationMonitor)(CLLocation *location, NSError * _Nullable error);



@property (nonatomic, strong) CMMotionManager *motitonManager;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CMAltimeter *altimeter;

@end

@implementation ACCSensorMonitor
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Proximity-距离
- (BOOL)startProximityMonitor:(void (^)(BOOL state))monitor {
    if (monitor == NULL) {
        return NO;
    }
    
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;

    self.proximityMonitor = monitor;
    self.proximityMonitor([UIDevice currentDevice].proximityState);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityStateDidChangeNotification:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    return YES;
}

- (void)stopProximityMonitor {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
    self.proximityMonitor = NULL;
}

- (void)proximityStateDidChangeNotification:(NSNotification *)notification {
    if (self.proximityMonitor) {
        self.proximityMonitor([UIDevice currentDevice].proximityState);
    }
}

#pragma mark - Battery-电量
- (BOOL)startBatteryMonitor:(void (^)(UIDeviceBatteryState state, float batteryLevel))monitor {
    if (monitor == NULL) {
        return NO;
    }
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;

    self.batteryMonitor = monitor;
    self.batteryMonitor([UIDevice currentDevice].batteryState, [UIDevice currentDevice].batteryLevel);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryStateDidChangeNotification:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryLevelDidChangeNotification:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    return YES;
}

- (void)stopBatteryMonitor {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    self.batteryMonitor = NULL;
}

- (void)batteryStateDidChangeNotification:(NSNotification *)notification {
    if (self.batteryMonitor) {
        self.batteryMonitor([UIDevice currentDevice].batteryState, [UIDevice currentDevice].batteryLevel);
    }
}

- (void)batteryLevelDidChangeNotification:(NSNotification *)notification {
    if (self.batteryMonitor) {
        self.batteryMonitor([UIDevice currentDevice].batteryState, [UIDevice currentDevice].batteryLevel);
    }
}

#pragma mark - Accelerometer-加速度计
- (BOOL)startAccelerometerMonitor:(void (^)(CMAcceleration acceleration, NSError * _Nullable error))monitor {
    return [self startAccelerometerMonitor:monitor updateInterval:1.0];
}
- (BOOL)startAccelerometerMonitor:(void (^)(CMAcceleration acceleration, NSError * _Nullable error))monitor updateInterval:(NSTimeInterval)updateInterval {
    if (monitor == NULL) {
        return NO;
    }
    
    if (![self.motitonManager isAccelerometerAvailable]) {
        return NO;
    }
    self.motitonManager.accelerometerUpdateInterval = updateInterval;
    [self.motitonManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        if (monitor) {
            monitor(accelerometerData.acceleration, error);
        }
    }];
    return YES;
}

- (void)stopAccelerometerMonitor {
    [self.motitonManager stopAccelerometerUpdates];
    [self releaseMotionManager];
}

#pragma mark - Gyro-陀螺仪计
- (BOOL)startGyroMonitor:(void (^)(CMRotationRate rotationRate, NSError * _Nullable error))monitor {
    return [self startGyroMonitor:monitor updateInterval:1.0];
}

- (BOOL)startGyroMonitor:(void (^)(CMRotationRate rotationRate, NSError * _Nullable error))monitor updateInterval:(NSTimeInterval)updateInterval {
    if (monitor == NULL) {
        return NO;
    }
    
    if (![self.motitonManager isGyroAvailable]) {
        return NO;
    }
    self.motitonManager.gyroUpdateInterval = updateInterval;
    [self.motitonManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        if (monitor) {
            monitor(gyroData.rotationRate, error);
        }
    }];
    return YES;
}

- (void)stopGyroMonitor {
    [self.motitonManager stopGyroUpdates];
    [self releaseMotionManager];
}
#pragma mark - Magnetometer-磁力计
- (BOOL)startMagnetometerMonitor:(void (^)(CMMagneticField magneticField, NSError * _Nullable error))monitor {
    return [self startMagnetometerMonitor:monitor updateInterval:1.0];
}

- (BOOL)startMagnetometerMonitor:(void (^)(CMMagneticField magneticField, NSError * _Nullable error))monitor updateInterval:(NSTimeInterval)updateInterval {
    if (monitor == NULL) {
        return NO;
    }
    
    if (![self.motitonManager isMagnetometerAvailable]) {
        return NO;
    }
    self.motitonManager.magnetometerUpdateInterval = updateInterval;
    [self.motitonManager startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
        if (monitor) {
            monitor(magnetometerData.magneticField, error);
        }
    }];
    return YES;
}

- (void)stopMagnetometerMonitor {
    [self.motitonManager stopMagnetometerUpdates];
    [self releaseMotionManager];
}
#pragma mark - DeviceMotion-设备运动信息（空间状态、陀螺仪数据、加速计数据、用户给设备带来的加速度、磁场信息、返回航向角度）
- (BOOL)startDeviceMotionMonitor:(void (^)(CMDeviceMotion * _Nullable motion, NSError * _Nullable error))monitor {
    return [self startDeviceMotionMonitor:monitor updateInterval:1.0];
}

- (BOOL)startDeviceMotionMonitor:(void (^)(CMDeviceMotion * _Nullable motion, NSError * _Nullable error))monitor updateInterval:(NSTimeInterval)updateInterval {
    if (monitor == NULL) {
        return NO;
    }
    
    if (![self.motitonManager isDeviceMotionAvailable]) {
        return NO;
    }
    self.motitonManager.deviceMotionUpdateInterval = updateInterval;
    [self.motitonManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        if (monitor) {
            monitor(motion, error);
        }
    }];
    return YES;
}

- (void)stopDeviceMotionMonitor {
    [self.motitonManager stopDeviceMotionUpdates];
    [self releaseMotionManager];
}
#pragma mark - Altimeter-海拔、气压
- (BOOL)startAltimeterMonitor:(void (^)(CMAltitudeData * _Nullable altitudeData, NSError * _Nullable error))monitor {
    if (monitor == NULL) {
        return NO;
    }
    
    if (![CMAltimeter isRelativeAltitudeAvailable]) {
        return NO;
    }
    
    [self.altimeter startRelativeAltitudeUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAltitudeData * _Nullable altitudeData, NSError * _Nullable error) {
        if (monitor) {
            monitor(altitudeData, error);
        }
    }];
    return YES;
}

- (void)stopAltimeterMonitor {
    [self.altimeter stopRelativeAltitudeUpdates];
    [self releaseAltimeter];
}

#pragma mark - Lightness-亮度
- (BOOL)startBrightnessMonitor:(void (^)(CGFloat lightness))monitor {
    return [self startBrightnessMonitor:monitor updateInterval:1.0];
}
- (BOOL)startBrightnessMonitor:(void (^)(CGFloat lightness))monitor updateInterval:(NSTimeInterval)updateInterval {
    if (monitor == NULL) {
        return NO;
    }
    
    [ACCTimerManager validateTimerForKey:@"BrightnessMonitor" after:0 interval:updateInterval block:^(NSInteger count) {
        monitor([UIScreen mainScreen].brightness);
    }];
    return YES;
}

- (void)stopBrightnessMonitor {
    [ACCTimerManager invalidateTimerForKey:@"BrightnessMonitor"];
}

#pragma mark - Location-位置
- (BOOL)startLocationMonitor:(void (^)(CLLocation *location, NSError * _Nullable error))monitor {
    if (monitor == NULL) {
        return NO;
    }
    
    if ([CLLocationManager locationServicesEnabled] == NO) {
        monitor(nil, [ACCSensorMonitor CYErrorWithCode:1003 description:@"定位服务不可用"]);
        return NO;
    }
    
    self.locationMonitor = monitor;
    [self.locationManager startUpdatingLocation];

    return YES;
}
- (void)stopLocationMonitor {
    [self.locationManager stopUpdatingLocation];
    [self releaseLocationManager];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:{
            // 主动获得授权
            [self.locationManager requestWhenInUseAuthorization];
            break;
        }
        case kCLAuthorizationStatusRestricted:
        {
            // 主动获得授权
            [self.locationManager requestWhenInUseAuthorization];
            break;
        }
        case kCLAuthorizationStatusDenied:{
            // 此时使用主动获取方法也不能申请定位权限
            // 类方法，判断是否开启定位服务
            if ([CLLocationManager locationServicesEnabled]) {
                self.locationMonitor(nil, [ACCSensorMonitor CYErrorWithCode:1002 description:@"定位服务被拒绝"]);
            } else {
                self.locationMonitor(nil, [ACCSensorMonitor CYErrorWithCode:1003 description:@"定位服务不可用"]);
            }
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:{
            break;
        }
        case kCLAuthorizationStatusAuthorizedWhenInUse:{
            break;
        }
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    if (self.locationMonitor == NULL) {
        return;
    }
    CLLocation * newLocation = [locations lastObject];
    // 判空处理
    if (newLocation.horizontalAccuracy < 0) {
        self.locationMonitor(nil, [ACCSensorMonitor CYErrorWithCode:1001 description:@"定位失败，请检查手机网络及定位"]);
    } else {
        self.locationMonitor(newLocation, nil);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    self.locationMonitor(nil, error);
}

#pragma mark - Release
- (void)releaseMotionManager {
    if (!self.motitonManager.isAccelerometerActive &&
        !self.motitonManager.isGyroActive &&
        !self.motitonManager.isMagnetometerActive &&
        !self.motitonManager.isDeviceMotionActive) {
        _motitonManager = nil;
    }
}

- (void)releaseAltimeter {
    _altimeter = nil;
}

- (void)releaseLocationManager {
    _locationManager = nil;
}

#pragma mark - CYError
+ (NSError *)CYErrorWithCode:(NSInteger)code description:(NSString *)description {
    return [NSError errorWithDomain:@"CYSensorError" code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

#pragma mark - Getter
- (CMMotionManager *)motitonManager {
    if (!_motitonManager) {
        _motitonManager = [[CMMotionManager alloc] init];
    }
    return _motitonManager;
}
- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        // 定位权限检查
        [_locationManager requestWhenInUseAuthorization];
        // 设定定位精准度
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];

    }
    return _locationManager;
}
- (CMAltimeter *)altimeter {
    if (!_altimeter) {
        _altimeter = [[CMAltimeter alloc] init];
    }
    return _altimeter;
}
@end

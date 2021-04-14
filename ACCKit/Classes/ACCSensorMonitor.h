//
//  ACCSensorMonitor.h
//  ACCKit
//
//  Created by CCyber on 2021/1/15.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCSensorMonitor : NSObject
#pragma mark - Proximity-距离
- (BOOL)startProximityMonitor:(void (^)(BOOL state))monitor;
- (void)stopProximityMonitor;

#pragma mark - Battery-电量
- (BOOL)startBatteryMonitor:(void (^)(UIDeviceBatteryState state, float batteryLevel))monitor;
- (void)stopBatteryMonitor;

#pragma mark - Accelerometer-加速度计
- (BOOL)startAccelerometerMonitor:(void (^)(CMAcceleration acceleration, NSError * _Nullable error))monitor;
- (BOOL)startAccelerometerMonitor:(void (^)(CMAcceleration acceleration, NSError * _Nullable error))monitor updateInterval:(NSTimeInterval)updateInterval;
- (void)stopAccelerometerMonitor;

#pragma mark - Gyro-陀螺仪计
- (BOOL)startGyroMonitor:(void (^)(CMRotationRate rotationRate, NSError * _Nullable error))monitor;
- (BOOL)startGyroMonitor:(void (^)(CMRotationRate rotationRate, NSError * _Nullable error))monitor updateInterval:(NSTimeInterval)updateInterval;
- (void)stopGyroMonitor;

#pragma mark - Magnetometer-磁力计
- (BOOL)startMagnetometerMonitor:(void (^)(CMMagneticField magneticField, NSError * _Nullable error))monitor;
- (BOOL)startMagnetometerMonitor:(void (^)(CMMagneticField magneticField, NSError * _Nullable error))monitor updateInterval:(NSTimeInterval)updateInterval;
- (void)stopMagnetometerMonitor;

#pragma mark - DeviceMotion-设备运动信息（空间状态、陀螺仪数据、加速计数据、用户给设备带来的加速度、磁场信息、返回航向角度）
- (BOOL)startDeviceMotionMonitor:(void (^)(CMDeviceMotion * _Nullable motion, NSError * _Nullable error))monitor;
- (BOOL)startDeviceMotionMonitor:(void (^)(CMDeviceMotion * _Nullable motion, NSError * _Nullable error))monitor updateInterval:(NSTimeInterval)updateInterval;
- (void)stopDeviceMotionMonitor;

#pragma mark - Altimeter-海拔、气压
- (BOOL)startAltimeterMonitor:(void (^)(CMAltitudeData * _Nullable altitudeData, NSError * _Nullable error))monitor;
- (void)stopAltimeterMonitor;

#pragma mark - Lightness-亮度
- (BOOL)startBrightnessMonitor:(void (^)(CGFloat lightness))monitor;
- (BOOL)startBrightnessMonitor:(void (^)(CGFloat lightness))monitor updateInterval:(NSTimeInterval)updateInterval;
- (void)stopBrightnessMonitor;

#pragma mark - Location-位置
- (BOOL)startLocationMonitor:(void (^)(CLLocation *location, NSError * _Nullable error))monitor;
- (void)stopLocationMonitor;
@end

NS_ASSUME_NONNULL_END

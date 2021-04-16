//
//  ACCViewController.m
//  ACCKit
//
//  Created by chengyb on 01/25/2021.
//  Copyright (c) 2021 chengyb. All rights reserved.
//

#import "ACCViewController.h"
#import <ACCKit/ACCKit.h>
#import <AVFoundation/AVFoundation.h>
@interface ACCViewController ()
@property (nonatomic, strong) ACCSensorMonitor *sensorMonitor;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;

@property (nonatomic, strong) ACCAudioRecorder *recorder;
@property (nonatomic, strong) ACCAudioPlayer *player;

@end

@implementation ACCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    //后台播放、默认外放和支持蓝牙耳机\Airplay
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowAirPlay error:&error];
    if (error) {
        NSLog(@"AVAudioSession setCategory error:%@",error);
    }
    
    [self setupRecorder];
    [self setupPlayer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onRecordButtonAction:(id)sender {
    UIButton *button = sender;
    NSString *title = button.titleLabel.text;
    if ([title isEqualToString:@"录音"]) {
        [self.player start];
        [self.recorder start];
        [button setTitle:@"停止录音" forState:UIControlStateNormal];
    } else {
        [self.recorder stop];
        [self.player stop];
        [button setTitle:@"录音" forState:UIControlStateNormal];
    }
}
- (IBAction)onMuteButtonAction:(id)sender {
    UIButton *button = sender;
    NSString *title = button.titleLabel.text;
    if ([title isEqualToString:@"静音"]) {
        [self.recorder setEnable:NO];
        [button setTitle:@"解除静音" forState:UIControlStateNormal];
    } else {
        [self.recorder setEnable:YES];
        [button setTitle:@"静音" forState:UIControlStateNormal];
    }
}

#pragma mark - Test Methond
- (void) testSensorMonitor {
    NSLog(@"Begin Monitor");

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
#pragma mark - Lazy Load
- (ACCSensorMonitor *)sensorMonitor{
    if (!_sensorMonitor) {
        _sensorMonitor = [ACCSensorMonitor new];
    }
    return _sensorMonitor;
}

- (void)setupRecorder {
    _recorder = [[ACCAudioRecorder alloc] initWithSampleRate:48000 channelsPerFrame:2 bitsPerChannel:16];
    __weak __typeof(self) weakSelf = self;
    [_recorder setRecordCallback:^(const void * _Nonnull data, uint size) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.player appendPCM:data size:size];
    }];
}

- (void)setupPlayer {
    _player = [[ACCAudioPlayer alloc] initWithSampleRate:48000 channelsPerFrame:2 bitsPerChannel:16];

}
@end

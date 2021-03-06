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

@property (nonatomic, strong) NSObject *lifeTimeTracker;
@end

@implementation ACCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self testTimer];
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

- (void)interruptionNotification:(NSNotification *)notification {
    id type = [notification.userInfo objectForKey:AVAudioSessionInterruptionTypeKey];    
    NSLog(@"type %@", type);
}

- (void)didBecomeActiveNotification:(NSNotification *)notification {
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        NSLog(@"AVAudioSession setCategory error:%@",error);
    }
    [self.recorder start];
    [self.player start];
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

- (void)testTimer {
    self.lifeTimeTracker = [[NSObject alloc] init];
    NSLog(@"timer-1 begin");
    ACCTimerOperator *op1 = [ACCTimerManager onceTimerWithDelay:1 block:^{
        NSLog(@"timer-1 trigger");
    } freeWith:self.lifeTimeTracker];
    
    NSLog(@"timer-2 begin");
    [ACCTimerManager onceTimerWithKey:@"timer-2" delay:2 block:^{
        NSLog(@"timer-2 trigger");
        
        BOOL result = [ACCTimerManager scheduledTimerWithKey:@"timer-3" fireDate:[NSDate dateWithTimeIntervalSinceNow:1] timeInterval:1 repeats:YES block:^(NSInteger count, BOOL * _Nonnull stop) {
            NSLog(@"timer-3 trigger %d", count);

        }];
        NSLog(@"timer-3 begin %@", result?@"succ":@"fail");

        NSLog(@"timer-4 begin");
        [ACCTimerManager scheduledTimerWithFireDate:[NSDate dateWithTimeIntervalSinceNow:10] timeInterval:1 repeats:YES block:^(NSInteger count, BOOL * _Nonnull stop) {
            NSLog(@"timer-4 trigger %d",count);
            
            if (count < 5) {
                BOOL result = [ACCTimerManager scheduledTimerWithKey:@"timer-3" fireDate:[NSDate dateWithTimeIntervalSinceNow:1] timeInterval:1 repeats:YES block:^(NSInteger count, BOOL * _Nonnull stop) {
                    NSLog(@"timer-3 trigger %d", count);

                }];
                
                NSLog(@"timer-3 begin %@", result?@"succ":@"fail");
            }
            else if (count == 5) {
                NSLog(@"all timer %@", [ACCTimerManager allTimerOperator]);
            } else if (count == 10) {
                if ([ACCTimerManager isTimerExistForKey:@"timer-3"]) {
                    NSLog(@"timer-3 invalidate");
                    [ACCTimerManager invalidateTimerForKey:@"timer-3"];
                }
            } else if (count > 20) {
                *stop = YES;
            }
        }];
    }];
    
    
}

- (void)testRecorderAndPlayer {
    //后台播放、默认外放和支持蓝牙耳机\Airplay
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowAirPlay|AVAudioSessionCategoryOptionMixWithOthers error:&error];
    if (error) {
        NSLog(@"AVAudioSession setCategory error:%@",error);
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self setupRecorder];
    [self setupPlayer];
    [self onRecordButtonAction:self.recordButton];
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

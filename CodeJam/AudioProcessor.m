//
//  AudioProcessor.m
//  yeap
//
//  Created by Raminelli, Alvaro on 5/20/17.
//  Copyright © 2017 Raminelli, Alvaro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioProcessor.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

#pragma mark Recording callback

#define UISHORT_TAP_MAX_DELAY 0.2
@interface UIShortTapGestureRecognizer : UITapGestureRecognizer

@end
@implementation UIShortTapGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(UISHORT_TAP_MAX_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                   {
                       // Enough time has passed and the gesture was not recognized -> It has failed.
                       if  (self.state != UIGestureRecognizerStateRecognized)
                       {
                           self.state = UIGestureRecognizerStateFailed;
                       }
                   });
}
@end

static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    // the data gets rendered here
    AudioBuffer buffer;
    
    // a variable where we check the status
    OSStatus status;
    
    /**
     This is the reference to the object who owns the callback.
     */
    AudioProcessor *audioProcessor = (__bridge AudioProcessor*) inRefCon;
    
    /**
     on this point we define the number of channels, which is mono
     for the iphone. the number of frames is usally 512 or 1024.
     */
    buffer.mDataByteSize = inNumberFrames * 2; // sample size
    buffer.mNumberChannels = 1; // one channel
    buffer.mData = malloc( inNumberFrames * 2); // buffer size
    
    // we put our buffer into a bufferlist array for rendering
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    // render input and check for error
    status = AudioUnitRender([audioProcessor audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    [audioProcessor hasError:status:__FILE__:__LINE__];
    
    // process the bufferlist in the audio processor
    [audioProcessor processBuffer:&bufferList];
    
    // clean up the buffer
    free(bufferList.mBuffers[0].mData);
    
    return noErr;
}

#pragma mark Playback callback

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
    /**
     This is the reference to the object who owns the callback. Ahmed
     */
    AudioProcessor *audioProcessor = (__bridge AudioProcessor*) inRefCon;
    
    // iterate over incoming stream an copy to output stream
    for (int i=0; i < ioData->mNumberBuffers; i++) {
        AudioBuffer buffer = ioData->mBuffers[i];
        
        // find minimum size
        UInt32 size = min(buffer.mDataByteSize, [audioProcessor audioBuffer].mDataByteSize);
        
        // copy buffer to audio buffer which gets played after function return
        memcpy(buffer.mData, [audioProcessor audioBuffer].mData, size);
        
        // set data size
        buffer.mDataByteSize = size;
    }
    return noErr;
}

#pragma mark objective-c class

@implementation AudioProcessor
@synthesize audioUnit, audioBuffer, gain,pauseMusic,surroundSound;

-(AudioProcessor*)init
{
    self = [super init];
    if (self) {
        gain = 6;
        [self initializeAudio];
    }
    
    //[UIAccelerometer sharedAccelerometer];
    
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions: AVAudioSessionCategoryOptionAllowBluetooth error:nil];
    //[[AVAudioSession sharedInstance] setActive:YES error:nil];
    //[[MPRemoteCommandCenter sharedCommandCenter].playCommand addTarget:self action:@selector(togglePlayCommand:)];
    //[[MPRemoteCommandCenter sharedCommandCenter].pauseCommand addTarget:self action:@selector(togglePauseCommand:)];
    //[[MPRemoteCommandCenter sharedCommandCenter].togglePlayPauseCommand addTarget:self action:@selector(togglePlayPauseCommand:)];
    NSLog(@"init Started");
   /* CMMotionManager* motionManager;
    if (motionManager ==nil) {
        motionManager= [[CMMotionManager alloc]init];
    }
    
    if ([motionManager isAccelerometerAvailable] == YES){
        NSLog(@"isAccelerometerAvailable");
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [motionManager startAccelerometerUpdates];
    
    [motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        NSLog(@"X: %i, Y: %i, Z: %i", accelerometerData.acceleration.x, accelerometerData.acceleration.y,accelerometerData.acceleration.z);
    }];
    }else{
        NSLog(@"No isAccelerometerAvailable");
    }*/
    
    /*UIViewController *objViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    doubleTapRecognizer.delegate = self;
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    singleTapRecognizer.delegate = self;
    
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];*/
    //
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(volumeChanged:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];*/
    //[[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:nil];

    return self;
}
/*- (void)volumeChanged:(NSNotification*)notification
{
    NSLog(@"volumeChanged");
    if([[notification.userInfo objectForKey:@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"] isEqualToString:@"ExplicitVolumeChange"])
    {
        float volume = [[[notification userInfo]
                         objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"]
                        floatValue];
    }
}*/

/*- (void)accelerometer:(UIAccelerometer *)accelerometer
        didAccelerate:(UIAcceleration *)acceleration
{
    NSLog(@"accelerometer");

    if (pause)
    {
        return;
    }
    if (handModeOn == NO)
    {
        if(pocketFlag == NO)
            return;
    }
    
    
    
    //  float accelZ = 0.0;
    //  float accelX = 0.0;
    //  float accelY = 0.0;
    
    rollingX = (acceleration.x * kFilteringFactor) + (rollingX * (1.0 - kFilteringFactor));
    rollingY = (acceleration.y * kFilteringFactor) + (rollingY * (1.0 - kFilteringFactor));
    rollingZ = (acceleration.z * kFilteringFactor) + (rollingZ * (1.0 - kFilteringFactor));
    
    float accelX = acceleration.x - rollingX;
    float accelY = acceleration.y - rollingY;
    float accelZ = acceleration.z - rollingZ;
    
    if((-accelZ >= [senstivity floatValue] && timerFlag) || (-accelZ <= -[senstivity floatValue] && timerFlag)|| (-accelX >= [senstivity floatValue] && timerFlag) || (-accelX <= -[senstivity floatValue] && timerFlag) || (-accelY >= [senstivity floatValue] && timerFlag) || (-accelY <= -[senstivity floatValue] && timerFlag))
    {
        timerFlag = false;
        addValueFlag = true;
        timer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
    }
    
    if(addValueFlag)
    {
        [self.accArray addObject:[NSNumber numberWithFloat:-accelX]];
        [self.accArray addObject:[NSNumber numberWithFloat:-accelY]];
        [self.accArray addObject:[NSNumber numberWithFloat:-accelZ]];
    }
}*/


-(void)tap:(UITapGestureRecognizer*)sender{
    NSLog(@"tap:%@",sender);
}

 -(BOOL)canBecomeFirstResponder{return YES;}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    NSLog(@"togglePlayCommand");
}

-(void)togglePlayPauseCommand:(MPRemoteCommand *)cmd{
    NSLog(@"togglePlayPauseCommandEvent");
    //[self stop];
}
-(void)togglePlayCommand:(MPRemoteCommand *)cmd{
    NSLog(@"togglePlayCommand");
}
-(void)togglePauseCommand:(MPRemoteCommand *)cmd{
    NSLog(@"togglePauseCommand");
}
/*- (void)togglePlayPauseCommandEvent:(id)__unused event
{
   NSLog(@"togglePlayPauseCommandEvent");
}*/

-(void)initializeAudio
{
    OSStatus status;
    
    //Reset Audio Unit & Audio Buffer
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    
    NSError *setCategoryError = nil;
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions: AVAudioSessionCategoryOptionAllowBluetooth| AVAudioSessionCategoryOptionMixWithOthers
                        error:&setCategoryError]) {
    }
    
    if (![session setPreferredIOBufferDuration:0.001
                  error:&setCategoryError]) {
    }
    
    
    //AVAudioSessionModeGameChat—For game apps. This mode is set automatically by apps that use a GKVoiceChat object and the AVAudioSessionCategoryPlayAndRecord category. Game chat mode uses the same routing parameters as the video chat mode.
    
    //AVAudioSessionModeVideoChat—For video chat apps such as FaceTime. The video chat mode can only be used with the AVAudioSessionCategoryPlayAndRecord category. Signals are optimized for voice through system-supplied signal processing and sets AVAudioSessionCategoryOptionAllowBluetooth and AVAudioSessionCategoryOptionDefaultToSpeaker.
    
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    //[[AVAudioSession sharedInstance] setActive:YES error:nil];
    NSLog(@"Latency %f", session.outputLatency);
    NSLog(@"Buffer Duration %f", session.IOBufferDuration);
    NSLog(@"Sample Rate %f", session.sampleRate);
    
    
    // We define the audio component
    AudioComponentDescription desc;
    
    //SET VoiceProcessingIO OR REMOTE
    desc.componentType = kAudioUnitType_Output; // we want to ouput
    
    //if(surroundSound){
        NSLog(@"Starting Surround Sound");
        desc.componentSubType = kAudioUnitSubType_RemoteIO; // we want in and ouput
    //}else{
    //    NSLog(@"Starting Without Surround Sound");
    //    desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO; // we want in and ouput
    //}
    //desc.componentType = kAudioUnitType_Output; // we want to ouput
    //desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO; // we want in and ouput
    
    //desc.componentType = kAudioUnitType_Mixer; // we want to ouput
    //desc.componentSubType = kAudioUnitSubType_MultiChannelMixer; // we want in and ouput
   
    //desc.componentType = kAudioUnitType_Mixer; // we want to ouput
    //desc.componentSubType = kAudioUnitSubType_AU3DMixerEmbedded; // we want in and ouput
   
    
    desc.componentFlags = 0; // must be zero
    desc.componentFlagsMask = 0; // must be zero
    desc.componentManufacturer = kAudioUnitManufacturer_Apple; // select provider
    
    // find the AU component by description
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // create audio unit by component
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    
    [self hasError:status:__FILE__:__LINE__];
    
    // define that we want record io on the input bus
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO, // use io
                                  kAudioUnitScope_Input, // scope to input
                                  kInputBus, // select input bus (1)
                                  &flag, // set flag
                                  sizeof(flag));
    [self hasError:status:__FILE__:__LINE__];
    
    // define that we want play on io on the output bus
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO, // use io
                                  kAudioUnitScope_Output, // scope to output
                                  kOutputBus, // select output bus (0)
                                  &flag, // set flag
                                  sizeof(flag));
    [self hasError:status:__FILE__:__LINE__];
    
    /*
     We need to specifie our format on which we want to work.
     We use Linear PCM cause its uncompressed and we work on raw data.
     for more informations check.
     
     We want 16 bits, 2 bytes per packet/frames at 44khz
     */
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= SAMPLE_RATE;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 1;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 2;
    audioFormat.mBytesPerFrame		= 2;
    
    
    
    // set the format on the output stream
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    
    [self hasError:status:__FILE__:__LINE__];
    
    // set the format on the input stream
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    [self hasError:status:__FILE__:__LINE__];
    
    
    
    /**
     We need to define a callback structure which holds
     a pointer to the recordingCallback and a reference to
     the audio processor object
     */
    AURenderCallbackStruct callbackStruct;
    
    // set recording callback
    callbackStruct.inputProc = recordingCallback; // recordingCallback pointer
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    
    // set input callback to recording callback on the input bus
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    
    [self hasError:status:__FILE__:__LINE__];
    
    /*
     We do the same on the output stream to hear what is coming
     from the input stream
     */
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    
    // set playbackCallback as callback on our renderer for the output bus
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    [self hasError:status:__FILE__:__LINE__];
    
    // reset flag to 0
    flag = 0;
    
    /*
     we need to tell the audio unit to allocate the render buffer,
     that we can directly write into it.
     */
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    
    
    /*
     we set the number of channels to mono and allocate our block size to
     1024 bytes.
     */
    audioBuffer.mNumberChannels = 1;
    audioBuffer.mDataByteSize = 512 * 2 ;
    audioBuffer.mData = malloc( 512 * 2);
    
    //status = AudioOutputUnitStop(audioUnit);
    //[self hasError:status:__FILE__:__LINE__];
    
    // Initialize the Audio Unit and cross fingers =)
    status = AudioUnitInitialize(audioUnit);
    [self hasError:status:__FILE__:__LINE__];
    
    
    NSLog(@"Started");
    
}

#pragma mark controll stream

-(void)start;
{
    //[self initializeAudio];
    
    //[[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    NSError *setCategoryError = nil;
    
    if(pauseMusic){
        if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                              withOptions: AVAudioSessionCategoryOptionAllowBluetooth error:&setCategoryError]) {
        }
    }else{
        if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                              withOptions: AVAudioSessionCategoryOptionAllowBluetooth| AVAudioSessionCategoryOptionMixWithOthers |AVAudioSessionCategoryOptionDuckOthers error:&setCategoryError]) {
        }
    }
    if(surroundSound){
        [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:nil];
    }else{
        [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeDefault error:nil];
    }
    
    // inquire about all available audio inputs
    NSLog(@"%@", [AVAudioSession sharedInstance].availableInputs);
    
    //using one of the input streams inquired above to get availableDataSources
    NSLog(@"%@", [AVAudioSession sharedInstance].availableInputs[0].dataSources);
    
    
    //Ask about latency and real-time audio results
    AVAudioSession *sessionRT = [AVAudioSession sharedInstance];
    NSLog(@"Starting Latency %f", sessionRT.outputLatency);
    NSLog(@"Starting Buffer Duration %f", sessionRT.IOBufferDuration);
    NSLog(@"Starting Sample Rate %f", sessionRT.sampleRate);
    
    // Force Phone Built in Microphone on, doesn't work with bluetooth
    //AVAudioSessionPortDescription *builtInPort = [AVAudioSession sharedInstance].availableInputs[0];
    //[[AVAudioSession sharedInstance] setPreferredInput:builtInPort error:nil];
    
    //    //Force input to be taken from A SPECIFIC Built-in mic, options ("Back", "Front", or "Bottom")
    //    AVAudioSessionPortDescription *port = [AVAudioSession sharedInstance].availableInputs[0];
    //    for (AVAudioSessionDataSourceDescription *source in port.dataSources) {
    //        if ([source.dataSourceName isEqualToString:@"Front"]) {
    //            [port setPreferredDataSource:source error:nil];
    //            //error message, couldn't setup Built-in Mic
    //            NSLog(@"Couldn't setup built-in mic");
    //        }
    //    }
    
    // Force Bluetooth headphones to work if available, (forces both BT input and output, can't separate the routes :( )
    //NSArray* routes = [AVAudioSession sharedInstance].availableInputs;
    //for (AVAudioSessionPortDescription* route in routes)
    //{
    //    if (route.portType == AVAudioSessionPortBluetoothHFP)
    //    {
    //        [[AVAudioSession sharedInstance] setPreferredInput:route error:nil];
    //    }
        
    //    if (route.portType == AVAudioSessionPortBluetoothA2DP)
    //    {
    //        [[AVAudioSession sharedInstance] setPreferredInput:route error:nil];
    //    }

    //}
    
    // Force Phone Built in Microphone on, doesn't work with bluetooth
    //AVAudioSessionPortDescription *builtInPort = [AVAudioSession sharedInstance].availableInputs[0];
    //[[AVAudioSession sharedInstance] setPreferredInput:builtInPort error:nil];
    
    // Force Phone Built in Microphone on (only if there is no Bluetooth connected), doesn't work with bluetooth
    NSArray* routes = [AVAudioSession sharedInstance].availableInputs;
    AVAudioSessionPortDescription *builtInPort = [AVAudioSession sharedInstance].availableInputs[0];
    for (AVAudioSessionPortDescription* route in routes)
    {
        if (route.portType == AVAudioSessionPortBluetoothHFP || route.portType == AVAudioSessionPortBluetoothA2DP)
        {
            // This device has bluetooth headphones, force the route to be BT
            [[AVAudioSession sharedInstance] setPreferredInput:route error:nil];
        } else {
            // This device has no BT headphones, it either has wired headphones or no headphones at all, force Built-in Mic
            [[AVAudioSession sharedInstance] setPreferredInput:builtInPort error:nil];
            
        }

    }
    if (![[AVAudioSession sharedInstance] setPreferredIOBufferDuration:0.001
                                         error:&setCategoryError]) {
    }
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    // start the audio unit. You should hear something, hopefully :)
    OSStatus status = AudioOutputUnitStart(audioUnit);
    [self hasError:status:__FILE__:__LINE__];

    
}
-(void)stop;
{
    // stop the audio unit
    OSStatus status = AudioOutputUnitStop(audioUnit);
    [self hasError:status:__FILE__:__LINE__];
    
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation  error:nil];
    
    //AudioOutputUnitStop(audioUnit);
    //AudioUnitUninitialize(audioUnit);
    //AudioComponentInstanceDispose(audioUnit);
    //audioUnit = nil;
    //[[AVAudioSession sharedInstance] setActive:YES error:nil];
}


-(void)setGain:(float)gainValue
{
    gain = gainValue;
}

-(float)getGain
{
    return gain;
}

-(void)setPauseMusic:(Boolean)pauseMusicValue
{
    pauseMusic = pauseMusicValue;
}
-(void)setSurroundSound:(Boolean)surroundSoundValue
{
    surroundSound = surroundSoundValue;
}


#pragma mark processing

-(void)processBuffer: (AudioBufferList*) audioBufferList
{
    AudioBuffer sourceBuffer = audioBufferList->mBuffers[0];
    
    // we check here if the input data byte size has changed
    if (audioBuffer.mDataByteSize != sourceBuffer.mDataByteSize) {
        // clear old buffer
        free(audioBuffer.mData);
        // assing new byte size and allocate them on mData
        audioBuffer.mDataByteSize = sourceBuffer.mDataByteSize;
        audioBuffer.mData = malloc(sourceBuffer.mDataByteSize);
    }
    
    /**
     Here we modify the raw data buffer now.
     In my example this is a simple input volume gain.
     iOS 5 has this on board now, but as example quite good.
     */
    SInt16 *editBuffer = audioBufferList->mBuffers[0].mData;
    
    // loop over every packet
    for (int nb = 0; nb < (audioBufferList->mBuffers[0].mDataByteSize / 2); nb++) {
        
        // we check if the gain has been modified to save resoures
        if (gain != 0) {
            // we need more accuracy in our calculation so we calculate with doubles
            double gainSample = ((double)editBuffer[nb]) / 32767.0;
            
            /*
             at this point we multiply with our gain factor
             we dont make a addition to prevent generation of sound where no sound is.
             
             no noise
             0*10=0
             
             noise if zero
             0+10=10
             */
            gainSample *= gain;
            
            /**
             our signal range cant be higher or lesser -1.0/1.0
             we prevent that the signal got outside our range
             */
            gainSample = (gainSample < -1.0) ? -1.0 : (gainSample > 1.0) ? 1.0 : gainSample;
            
            /*
             This thing here is a little helper to shape our incoming wave.
             The sound gets pretty warm and better and the noise is reduced a lot.
             Feel free to outcomment this line and here again.
             
             You can see here what happens here http://silentmatt.com/javascript-function-plotter/
             Copy this to the command line and hit enter: plot y=(1.5*x)-0.5*x*x*x
             */
            
            gainSample = (1.5 * gainSample) - 0.5 * gainSample * gainSample * gainSample;
            
            // multiply the new signal back to short
            gainSample = gainSample * 32767.0;
            
            // write calculate sample back to the buffer
            editBuffer[nb] = (SInt16)gainSample;
        }
    }
    
    // copy incoming audio data to the audio buffer
    memcpy(audioBuffer.mData, audioBufferList->mBuffers[0].mData, audioBufferList->mBuffers[0].mDataByteSize);
}

#pragma mark Error handling

-(void)hasError:(int)statusCode:(char*)file:(int)line
{
    if (statusCode) {
        printf("Error Code responded %d in file %s on line %d\n", statusCode, file, line);
        exit(-1);
    }
}


@end

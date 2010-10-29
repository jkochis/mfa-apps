#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "BevelView.h"
#import "StopFactory.h"
#import "StopGroup.h"
#import "TapDetectingImageView.h"
#import	"TapDetectingView.h"

@interface StopGroupController : UIViewController <TapDetectingImageViewDelegate, TapDetectingViewDelegate, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource> {
	
	AVAudioPlayer *audioPlayer;
	NSTimer *updateTimer;
	
	IBOutlet BevelView *progressView;
	IBOutlet UILabel *currentTime;
	IBOutlet UILabel *duration;
	IBOutlet UISlider *progressBar;
	BOOL isSeeking;
	
	IBOutlet UIButton *playButton;
	IBOutlet UIView *volumeView;
	IBOutlet UISlider *volumeSlider;
	NSTimer *controlsTimer;
	
	IBOutlet UIScrollView *scrollView;
	IBOutlet UIImageView *stopTableShadow;
	IBOutlet UITableView *stopTable;
	TapDetectingImageView *imageView;
	BOOL lastRowNeedsPadding;
	
	UIView *moviePlayerHolder;
	TapDetectingView *moviePlayerTapDetector;
	MPMoviePlayerController *moviePlayerController;
	BOOL moviePlayerIsPlaying;
	
	StopGroup *stopGroup;
}

@property (nonatomic, retain) IBOutlet UITableView *stopTable;
@property (nonatomic, retain) StopGroup *stopGroup;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayerController;

- (id)initWithStopGroup:(StopGroup*)stop;

- (IBAction)progressSliderTouchDown:(UISlider *)sender;
- (IBAction)progressSliderTouchUp:(UISlider *)sender;
- (IBAction)progressSliderMoved:(UISlider *)sender;
- (IBAction)playButtonPressed:(UIButton *)sender;
- (IBAction)volumeSliderMoved:(UISlider *)sender;

@end

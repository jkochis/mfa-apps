#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "ImageStop.h"
#import "TapDetectingImageView.h"

@interface ImageStopController : UIViewController <UIScrollViewDelegate, TapDetectingImageViewDelegate> {
	
	IBOutlet UIScrollView *scrollView;
	TapDetectingImageView *imageView;	
	ImageStop *imageStop;
}

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIImageView *imageView;

@property (nonatomic, retain) ImageStop *imageStop;

- (id)initWithImageStop:(ImageStop *)stop;

@end

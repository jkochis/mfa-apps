#import <UIKit/UIKit.h>

#import "WebStop.h"

@interface WebStopController : UIViewController {
	
	IBOutlet UIWebView *webView;	
	WebStop *webStop;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) WebStop *webStop;

- (id)initWithWebStop:(WebStop *)stop;

@end
